require 'nokolexbor'
require 'http'
require 'parallel'
require 'json'

module GoogleLocalResultsAiParser
  DEFAULT_SERVER = 'https://api-inference.huggingface.co/models/serpapi/bert-base-local-results'.freeze
  DEFAULT_SEPARATOR_REGEX = /\n|·|⋅/.freeze
  DEFAULT_REJECTED_CSS = "[role='heading'], a[ping], [class*='label']".freeze
  DEFAULT_BROKEN_CSS = "b:has(::text)".freeze
  DEFAULT_MAX_ITERATION = 1

  class CustomError < StandardError
    attr_reader :message

    def initialize(message = "\nThere is a problem with the connection to the server. Try setting up a private server or configure your server credentials.\nIf you are using the public endpoint, you may wait for the model to load.")
      @message = message
      super
    end

    def to_s
      "#{self.class}: #{message}"
    end
  end

  class << self
    def parse_multiple(html_parts: nil, bearer_token: nil, server: DEFAULT_SERVER, separator_regex: DEFAULT_SEPARATOR_REGEX, rejected_css: DEFAULT_REJECTED_CSS, broken_css: DEFAULT_BROKEN_CSS, iteration: DEFAULT_MAX_ITERATION, debug: false, no_cache: false)
      response_bodies = Parallel.map(html_parts, in_threads: html_parts.size) do |html|
        parse(html: html, bearer_token: bearer_token, server: server, separator_regex: separator_regex, rejected_css: rejected_css, broken_css: broken_css, iteration: iteration, debug: debug, no_cache: no_cache)
      end
    end

    def parse(html: nil, bearer_token: nil, server: DEFAULT_SERVER, separator_regex: DEFAULT_SEPARATOR_REGEX, rejected_css: DEFAULT_REJECTED_CSS, broken_css: DEFAULT_BROKEN_CSS, iteration: DEFAULT_MAX_ITERATION, debug: false, no_cache: false)
      doc = Nokolexbor::HTML(html)

      # Rejecting title, buttons, and label
      doc.css(rejected_css).remove

      # Breaking down bold text to reduce noise
      doc.css(DEFAULT_BROKEN_CSS).each { |b| b.parent.replace(Nokolexbor::Text.new(b.parent.text, doc)) }
      
      # Separating and cleaning the text
      unsplit_text = doc.at_css('html').text
      extracted_text = doc.css("::text").map {|part| part.text.strip}.compact.join("\n")
      split_text = extracted_text.split(separator_regex)
      cleaned_text = split_text.map(&:strip).reject(&:empty?).flatten
    
      # Making parallel requests to server for classification
      time_start = Time.now
      results = parallel_post_requests(server, bearer_token, cleaned_text, no_cache)
      time_end = Time.now
      
      # After-fix and sorting of results
      results = sort_results(results, extracted_text, unsplit_text, iteration, doc)
      final_results = transform_hash(results, unsplit_text)

      unless debug
        final_results # Default output
      else
        time_taken = time_end - time_start # Time taken to make requests for debugging purpurses
        return final_results, time_taken
      end
    end

    def transform_hash(results, unsplit_text)
      # Transforming the final results into a hash with classifications
      final_results = {}
      results.each do |result|
        label = result[:result][0][0]["label"]
        value = result[:input]

        if final_results[label]
          # Combine the text for same elements
          final_results[label] = unsplit_text[/#{final_results[label]}(.+|\n)#{value}/]
        else
          # Directly assign values
          final_results[label] = value
        end
      end
      
      final_results
    end

    def sort_results(results, extracted_text, unsplit_text, iteration, doc)
      # Some endpoints load array of hashes whereas some of them
      # load a wrapped version of this. The Free Inference API
      # should be taken as reference since most people will
      # prototype there.
      results.map! do |item|
        if item[:result][0].is_a?(Hash)
          item[:result] = [item[:result]]
        end
        item
      end

      # Make at most 2 iterations for after-corrections
      (0..iteration).each do |i|
        begin
          # Check if some results contain clashes, or need to be merged
          label_order = results.map {|result| result[:result][0][0]["label"]}
        rescue
          raise CustomError
        end

        # Safety measures
        results, label_order = check_if_button_text(results, label_order, doc)

        # Find duplicates
        duplicates = find_duplicates(label_order)

        # Known clashes
        results, label_order, duplicates = button_text_as_hours_confusion(results, label_order, duplicates)
        results, label_order, duplicates = button_text_as_address_confusion(results, label_order, duplicates)
        results, label_order, duplicates = button_text_as_service_options_confusion(results, label_order, duplicates)
        results, label_order, duplicates = service_options_as_type_confusion(results, label_order, duplicates)
        results, label_order, duplicates = description_as_hours_confusion(results, label_order, duplicates)
        results, label_order, duplicates = description_as_type_confusion(results, label_order, duplicates)
        results, label_order, duplicates = reviews_as_rating_confusion(results, label_order, duplicates)
        results, label_order, duplicates = reviews_as_price_confusion(results, label_order, duplicates)
        results, label_order, duplicates = service_options_as_description_or_type_confusion(results, label_order, duplicates)
        
        # General clashes
        line_result = check_if_on_different_lines(results, duplicates, unsplit_text)
        duplicates.each_with_index do |duplicate, duplicate_index|
          if line_result[duplicate_index] != []
            # General clash
            line_result[duplicate_index].each do |clash|
              first_result_score = results[clash[0]][:result][0][0]["score"]
              second_result_score = results[clash[1]][:result][0][0]["score"]

              if first_result_score > second_result_score
                clash_index = clash[1]
              else
                clash_index = clash[0]
              end

              # Zero out the false classification, and put it to last position
              primary_prediction = results[clash_index][:result][0][0]
              primary_prediction["score"] = 0.0
              second_prediction = results[clash_index][:result][0][1]
              results[clash_index][:result][0][0] = second_prediction
              results[clash_index][:result][0].delete_at(1)
              results[clash_index][:result][0] << primary_prediction
            end
          end
        end

        # Check one more time to see if there's any clashes left
        label_order = results.map {|result| result[:result][0][0]["label"]}
        duplicates = find_duplicates(label_order)
        line_result = check_if_on_different_lines(results, duplicates, unsplit_text)
        no_clashes = line_result.all? { |sub_array| sub_array.empty? }

        if no_clashes
          break
        end
      end

      results
    end

    # Items on different lines will be combined in `unsplit_text`.
    # We can make combinations of 2 to eliminate the bad weed.
    def check_if_on_different_lines(results, duplicates, unsplit_text)
      line_result = []
      duplicates.each do |duplicate|
        combinations = duplicate.each_cons(2).to_a

        sub_result = []
        
        combinations.each do |combination|
          combined_text = combination.map {|index| "#{results[index][:input]}"}.join
          sub_result << combination if unsplit_text.include?(combined_text)
        end

        line_result << sub_result
      end

      line_result
    end

    # Find duplicate labels and group them
    def find_duplicates(label_order)
      indices = []
      label_order.each_with_index do |label, index|
        common_indices = label_order.map.with_index do |compared_label, compared_index|
          if compared_label == label && compared_index != index && !indices.flatten.include?(index)
            compared_index
          end
        end.compact

        if common_indices != []
          indices << [index, common_indices].flatten
        end
      end

      indices
    end

    # Double checking residue button text
    # The model hasn't encountered this behaviour.
    # This is a safety measure.
    def check_if_button_text(results, label_order, doc)
      return results, label_order unless label_order.include?("button text")
      
      button_indices = label_order.map.with_index {|label, index| index if label == "button text"}.compact
      button_results = []

      button_indices.each do |button_index|
        button_result = results[button_index]
        button_text = results[button_index][:input]
        has_button_text = doc.css("[href], [ping]").any? {|element| element.text.include?(button_text)}
        
        if has_button_text
          # If it is really a button text inside a link
          button_results << button_result
        else
          # Zero out the `button text`, and put it to last position
          results[button_index][:result][0][0] = results[button_index][:result][0][1]
          results[button_index][:result][0].delete_at(1)
          button_result[:result][0][0]["score"] = 0.0
          results[button_index][:result][0] << button_result[:result][0][0]
          label_order[button_index] = results[button_index][:result][0][0]["label"]
        end
      end

      # Clear the buttons
      button_results.each do |button_result|
        results.delete(button_result)
      end

      # Clear the labels
      label_order.delete_if {|label| label == "button text"}

      return results, label_order
    end

    def button_text_as_hours_confusion(results, label_order, duplicates)
      known_errors = ["Expand more"]
      confusion_condition = results.any? {|result| known_errors.include?(result[:input])}
      return results, label_order, duplicates unless confusion_condition

      hours_duplicate = duplicates.find.with_index do |duplicate, duplicate_index|
        if results[duplicate[0]][:result][0][0]["label"] == "hours"
          duplicate_index
        end
      end

      if hours_duplicate
        # Delete the known button text directly
        results.delete_at(hours_duplicate[-1])
        
        # Rearranging `label_order`
        label_order.delete_at(hours_duplicate[-1])
        
        # Rearranging duplicates
        last_item = duplicates[duplicates.index(hours_duplicate)][-1]
        duplicates[duplicates.index(hours_duplicate)].delete(last_item)

        if (duplicate_arr = duplicates[duplicates.index(hours_duplicate)]) && duplicate_arr.size == 1
          duplicates.delete(duplicate_arr)
        end
      else
        known_error_indices = results.map.with_index {|result, result_index| result_index if known_errors.include?(result[:input])}.compact

        known_error_indices.each do |index|
          # Delete the known button text directly
          results.delete_at(index)

          # Rearranging `label_order`
          label_order.delete_at(index)
        end
      end

      return results, label_order, duplicates
    end

    # 104 Ave ... Share
    # Fixes `Share`
    def button_text_as_address_confusion(results, label_order, duplicates)
      known_errors = ["Share"]
      confusion_condition = results.any? {|result| known_errors.include?(result[:input])}
      return results, label_order, duplicates unless confusion_condition

      address_duplicate = duplicates.find.with_index do |duplicate, duplicate_index|
        if results[duplicate[0]][:result][0][0]["label"] == "address"
          duplicate_index
        end
      end

      # Delete the known button text directly
      results.delete_at(address_duplicate[-1])
      
      # Rearranging `label_order`
      label_order.delete_at(address_duplicate[-1])
      
      # Rearranging duplicates
      last_item = duplicates[duplicates.index(address_duplicate)][-1]
      duplicates[duplicates.index(address_duplicate)].delete(last_item)

      if (duplicate_arr = duplicates[duplicates.index(address_duplicate)]) && duplicate_arr.size == 1
        duplicates.delete(duplicate_arr)
      end

      return results, label_order, duplicates
    end

    # Order pickup
    # Fixes `Order pickup`
    def button_text_as_service_options_confusion(results, label_order, duplicates)
      known_errors = ["Order pickup"]
      confusion_condition = results.any? {|result| known_errors.include?(result[:input])}
      return results, label_order, duplicates unless confusion_condition

      service_options_indexes = results.map {|result| results.index(result) if known_errors.include?(result[:input])}.compact

      service_options_duplicate = duplicates.find.with_index do |duplicate, duplicate_index|
        if results[duplicate[0]][:result][0][0]["label"] == "service options"
          duplicate_index
        end
      end

      # Delete the known button text directly
      service_options_indexes.each {|index| results.delete_at(index)}
      
      # Rearranging `label_order`
      service_options_indexes.each {|index| label_order.delete_at(index)}
      
      # Rearranging duplicates
      service_options_indexes.each do |index|
        duplicates.each_with_index do |duplicate, duplicate_index|
          if duplicate.include?(index)
            duplicates[duplicate_index].delete(index)
          end
        end
      end

      if service_options_duplicate && (duplicate_arr = duplicates[duplicates.index(service_options_duplicate)]) && duplicate_arr.size == 1
        duplicates.delete(duplicate_arr)
      end

      return results, label_order, duplicates
    end

    # 3.4 .. (1.4K)
    # Fixes `(1.4K)`
    def reviews_as_rating_confusion(results, label_order, duplicates)
      rating_duplicate = duplicates.find.with_index do |duplicate, duplicate_index|
        if results[duplicate[0]][:result][0][0]["label"] == "rating"
          duplicate_index
        end
      end

      if rating_duplicate && results[rating_duplicate[-1]][:input][/\(\d+\.\d+\w\)/]
        # Zero out the `rating`, and put it to last position
        reviews_hash = results[rating_duplicate[-1]][:result][0].find {|hash| hash["label"] == "reviews" }
        reviews_index = results[rating_duplicate[-1]][:result][0].index(reviews_hash)
        results[rating_duplicate[-1]][:result][0][0] = {"label" => "reviews", "score" => 1.0}
        results[rating_duplicate[-1]][:result][0].delete_at(reviews_index)
        results[rating_duplicate[-1]][:result][0] << {"label" => "rating", "score" => 0.0}
        
        # Rearranging `label_order`
        label_order[rating_duplicate[-1]] = "reviews"
        
        # Rearranging duplicates
        last_item = duplicates[duplicates.index(rating_duplicate)][-1]
        duplicates[duplicates.index(rating_duplicate)].delete(last_item)

        if (duplicate_arr = duplicates[duplicates.index(rating_duplicate)]) && duplicate_arr.size == 1
          duplicates.delete(duplicate_arr)
        end
      end

      return results, label_order, duplicates
    end

    # (1.6K) .. $
    # Fixes `(1.6K)`
    def reviews_as_price_confusion(results, label_order, duplicates)
      price_duplicate = duplicates.find.with_index do |duplicate, duplicate_index|
        if results[duplicate[0]][:result][0][0]["label"] == "price"
          duplicate_index
        end
      end

      if price_duplicate && results[price_duplicate[0]][:input][/\(\d+\.\d+\w\)/]
        # Zero out the `price`, and put it to last position
        reviews_hash = results[price_duplicate[-1]][:result][0].find {|hash| hash["label"] == "reviews" }
        reviews_index = results[price_duplicate[-1]][:result][0].index(reviews_hash)
        results[price_duplicate[0]][:result][0][0] = {"label" => "reviews", "score" => 1.0}
        results[price_duplicate[0]][:result][0].delete_at(reviews_index)
        results[price_duplicate[0]][:result][0] << {"label" => "price", "score" => 0.0}
        
        # Rearranging `label_order`
        label_order[price_duplicate[0]] = "reviews"
        
        # Rearranging duplicates
        first_item = duplicates[duplicates.index(price_duplicate)][0]
        duplicates[duplicates.index(price_duplicate)].delete(first_item)

        if (duplicate_arr = duplicates[duplicates.index(price_duplicate)]) && duplicate_arr.size == 1
          duplicates.delete(duplicate_arr)
        end
      end

      return results, label_order, duplicates
    end

    # Coffee shop ... Iconic Seattle-based coffeehouse chain
    # Fixes `Iconic Seattle-based coffeehouse chain`
    def description_as_type_confusion(results, label_order, duplicates)
      return results, label_order, duplicates if label_order[-1] != "type"

      # Zero out the `type`, and put it to last position
      description_hash = results[-1][:result][0].find {|hash| hash["label"] == "description" }
      description_index = results[-1][:result][0].index(description_hash)
      results[-1][:result][0][0] = {"label" => "description", "score" => 1.0}
      results[-1][:result][0].delete_at(description_index)
      results[-1][:result][0] << {"label" => "type", "score" => 0.0}

      # Rearranging `label_order`
      label_order[-1] = "description"

      # Rearranging duplicates if there's any duplication
      if duplicates.flatten.include?(label_order.size - 1)
        type_duplicate = duplicates.find {|duplicate| duplicate.include?(label_order.size - 1)}
        last_item = duplicates[duplicates.index(type_duplicate)][-1]
        duplicates[duplicates.index(type_duplicate)].delete(last_item)
        
        if (duplicate_arr = duplicates[duplicates.index(type_duplicate)]) && duplicate_arr.size == 1
          duplicates.delete(duplicate_arr)
        end
      end

      return results, label_order, duplicates
    end

    # Drive through: Open ⋅ Closes 12 AM
    # Fixes `Closes 12 AM``
    def description_as_hours_confusion(results, label_order, duplicates)
      description_index = label_order.index("description")
      hours_index =  label_order.rindex("hours")

      # Description may or may not be a duplicate.
      # This is a known error from the model, so it has to be handled in any case.
      if description_index && hours_index && description_index + 1 == hours_index
        # Zero out the `hours`, and put it to last position
        description_hash = results[hours_index][:result][0].find {|hash| hash["label"] == "description" }
        description_index = results[hours_index][:result][0].index(description_hash)
        results[hours_index][:result][0][0] = {"label" => "description", "score" => 1.0}
        results[hours_index][:result][0].delete_at(description_index)
        results[hours_index][:result][0] << {"label" => "hours", "score" => 0.0}
        
        # Rearranging `label_order`
        label_order[hours_index] = "description"
        
        # Rearranging duplicates if there's any duplication
        if duplicates.flatten.include?(hours_index)
          hours_duplicate = duplicates.find {|duplicate| duplicate.include?(hours_index)}
          last_item = duplicates[duplicates.index(hours_duplicate)][-1]
          duplicates[duplicates.index(hours_duplicate)].delete(last_item)
          
          if (duplicate_arr = duplicates[duplicates.index(hours_duplicate)]) && duplicate_arr.size == 1
            duplicates.delete(duplicate_arr)
          end
        end
      end

      return results, label_order, duplicates
    end

    # On-site services, Online appointments
    # Fixes `On-site services`, `Online appointments`
    def service_options_as_description_or_type_confusion(results, label_order, duplicates)
      known_errors = [
        "On-site services",
        "On-site services not available",
        "Onsite services",
        "Onsite services not available",
        "Online appointments",
        "Online appointments not available",
        "Online estimates",
        "Online estimates not available",
        "Takeaway"
      ]
      caught_results_indices = results.map.with_index {|result, index| index if known_errors.include?(result[:input]) && result[:result][0][0]["label"] != "service options"}.compact

      not_service_option_duplicates = []
      caught_results_indices.each do |caught_index|
        duplicates.each.with_index do |duplicate, duplicate_index|
          if duplicate.include?(caught_index)
            not_service_option_duplicates << duplicate_index
          end
        end
      end

      # Zero out the `type` or `description`, and put it to last position
      caught_results_indices.each do |caught_index|
        service_options_hash = results[caught_index][:result][0].find {|hash| hash["label"] == "service options" }
        service_options_index = results[caught_index][:result][0].index(service_options_hash)
        old_result_hash = results[caught_index][:result][0][0]
        results[caught_index][:result][0][0] = {"label" => "service options", "score" => 1.0}
        results[caught_index][:result][0].delete_at(service_options_index)
        old_result_hash["score"] = 0.0
        results[caught_index][:result][0] << old_result_hash
      end
      
      # Rearranging `label_order`
      caught_results_indices.each {|caught_index| label_order[caught_index] = "service options"}

      return results, label_order, duplicates if not_service_option_duplicates == []
      # Rearranging duplicates
      not_service_option_duplicates.each do |not_service_option_duplicate|
        last_item = duplicates[not_service_option_duplicate][-1]
        duplicates[not_service_option_duplicate].delete(last_item)
      end

      not_service_option_duplicates.each do |not_service_option_duplicate|
        if (duplicate_arr = duplicates[not_service_option_duplicate]) && duplicate_arr.size == 1
          duplicates.delete(duplicate_arr)
        end
      end

      return results, label_order, duplicates
    end

    # Takeaway ⋅ Dine-in ...
    # Fixes `Takeaway`
    def service_options_as_type_confusion(results, label_order, duplicates)
      type_duplicate = duplicates.find.with_index do |duplicate, duplicate_index|
        if results[duplicate[0]][:result][0][0]["label"] == "type"
          duplicate_index
        end
      end

      if type_duplicate && (adjacent_item = results[type_duplicate[-1] + 1]) && adjacent_item[:result][0][0]["label"] == "service options"
        # Zero out the `type`, and put it to last position
        service_options_hash = results[type_duplicate[-1]][:result][0].find {|hash| hash["label"] == "service options" }
        service_options_index = results[type_duplicate[-1]][:result][0].index(service_options_hash)
        results[type_duplicate[-1]][:result][0][0] = {"label" => "service options", "score" => 1.0}
        results[type_duplicate[-1]][:result][0].delete_at(service_options_index)
        results[type_duplicate[-1]][:result][0] << {"label" => "type", "score" => 0.0}
        
        # Rearranging `label_order`
        label_order[type_duplicate[-1]] = "service_options"
        
        # Rearranging duplicates
        last_item = duplicates[duplicates.index(type_duplicate)][-1]
        duplicates[duplicates.index(type_duplicate)].delete(last_item)

        if (duplicate_arr = duplicates[duplicates.index(type_duplicate)]) && duplicate_arr.size == 1
          duplicates.delete(duplicate_arr)
        end
      end

      return results, label_order, duplicates
    end

    private

    def parallel_post_requests(server, bearer_token, inputs, no_cache)
      response_bodies = Parallel.map(inputs, in_threads: inputs.size) do |input|
        post_request(server, bearer_token, input, no_cache)
      end

      response_bodies
    end

    def post_request(server, bearer_token, input, no_cache)
      url = URI.parse(server)
      headers = unless no_cache
        { 'Authorization' => "Bearer #{bearer_token}", 'Content-Type' => 'application/json' }
      else
        { 'Authorization' => "Bearer #{bearer_token}", 'Content-Type' => 'application/json', 'Cache-Control' => 'no-cache' } # To benchmark initial load of the model
      end

      body = { inputs: input, parameters: {top_k: 11}}.to_json # 11 represents the number of labels the model has
    
      response = HTTP.headers(headers).post(url, body: body)
      response_body = JSON.parse(response.body)
    
      { input: input, result: response_body }
    end
  end
end
