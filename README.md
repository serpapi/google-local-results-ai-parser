<h1 align="center">Google Local Results AI Parser</h1>

<div align="center">

  <a href="">[![Gem Version][gem-shield]][gem-url]</a>
  <a href="">[![Contributors][contributors-shield]][contributors-url] </a>
  <a href="">[![Forks][forks-shield]][forks-url]</a>
  <a href="">[![Stargazers][stars-shield]][stars-url]</a>
  <a href="">[![Issues][issues-shield]][issues-url]</a>
  <a href="">[![Issues][issuesclosed-shield]][issuesclosed-url]</a>
  <a href="">[![MIT License][license-shield]][license-url]</a>

</div>

`google-local-results-ai-parser` is a gem developed by [SerpApi](https://serpapi.com/). It provides a parser for extracting structured data from Google Local Search Results using the [`serpapi/bert-base-local-results` transformer model](https://huggingface.co/serpapi/bert-base-local-results), enabling you to parse HTML content of Google Local Results Listings in English, extract relevant information, and classify it into different categories such as ratings, reviews, descriptions, and more.

<div align="center"><b>Relevant Sources</b></div>

- [**Google Local Results AI Server**](https://github.com/serpapi/google-local-results-ai-server): Open-Source server code for mimicking Huggingface Inference API.
- [**BERT-Based Classification Model for Google Local Listings**](https://huggingface.co/serpapi/bert-base-local-results): BERT-based classification model developed using the Hugging Face library, and a dataset gathered by SerpApi's Google Local API.
- [**SerpApi's Google Local Pack Results API Documentation**](https://serpapi.com/local-pack): A documentation on SerpApi's Scraper API for inline Google Local Results in Google queries. The keys served in this gem are in coherence with SerpApi's scrapers.
- [**SerpApi's Google Local Results API Documentation**](https://serpapi.com/google-local-api): A documentation on SerpApi's Scraper API for Google Local Search Results. The keys served in this gem are in coherence with SerpApi's scrapers.
- [**Nokolexbor**](https://github.com/serpapi/nokolexbor): Drop-in replacement for Nokogiri. It's 5.2x faster at parsing HTML and up to 997x faster at CSS selectors.
---

<h2 align="center">Installation</h2>

Add this line to your application's Gemfile:
```
gem 'google-local-results-ai-parser'
```
And then execute the following in your terminal:
```bash
$ bundle install
```
Or install it yourself in your terminal:
```
$ gem install google-local-results-ai-parser
```
---
<h2 align="center">Usage</h2>

To use the `google-local-results-ai-parser` gem, you need to include the necessary dependencies:
```rb
require 'google-local-results-ai-parser'
require 'nokolexbor'
require 'http'
require 'parallel'
require 'json'
```

<h3 align="center">Parsing HTML</h3>

The main functionality of the gem is to parse HTML content and extract structured data from it. You can use the `GoogleLocalResultsAiParser.parse` method to parse a single HTML document:

```rb
html = "<div jscontroller=\"AtSb\" class=\"w7Dbne\" data-record-click-time=\"false\" id=\"tsuid_25\" jsdata=\"zt2wNd;_;BvbRxs V6f1Id;_;BvbRxw\" jsaction=\"rcuQ6b:npT2md;e3EWke:kN9HDb\" data-hveid=\"CBUQAA\"><div jsname=\"jXK9ad\" class=\"uMdZh tIxNaf\" jsaction=\"mouseover:UI3Kjd\"><div class=\"VkpGBb\"><div class=\"cXedhc\"><a class=\"vwVdIc wzN8Ac rllt__link a-no-hover-decoration\" jsname=\"kj0dLd\" data-cid=\"12176489206865957637\" jsaction=\"click:h5M12e;\" role=\"link\" tabindex=\"0\" data-ved=\"2ahUKEwiS1P3_j-P7AhXnVPEDHa0oAiAQvS56BAgVEAE\"><div><div class=\"rllt__details\"><div class=\"dbg0pd\" aria-level=\"3\" role=\"heading\"><span class=\"OSrXXb\">Y Coffee</span></div><div><span class=\"Y0A0hc\"><span class=\"yi40Hd YrbPuc\" aria-hidden=\"true\">4.0</span><span class=\"z3HNkc\" aria-label=\"Rated 4.0 out of 5,\" role=\"img\"><span style=\"width:56px\"></span></span><span class=\"RDApEe YrbPuc\">(418)</span></span> · <span aria-label=\"Moderately expensive\" role=\"img\">€€</span> · Coffee shop</div><div>Nicosia</div><div class=\"pJ3Ci\"><span>Iconic Seattle-based coffeehouse chain</span></div></div></div></a><a class=\"uQ4NLd b9tNq wzN8Ac rllt__link a-no-hover-decoration\" aria-hidden=\"true\" tabindex=\"-1\" jsname=\"kj0dLd\" data-cid=\"12176489206865957637\" jsaction=\"click:h5M12e;\" role=\"link\" data-ved=\"2ahUKEwiS1P3_j-P7AhXnVPEDHa0oAiAQvS56BAgVEA4\"><g-img class=\"gTrj3e\"><img id=\"pimg_3\" src=\"https://lh5.googleusercontent.com/p/AF1QipPaihclGQYWEJpMpBnBY8Nl8QWQVqZ6tF--MlwD=w184-h184-n-k-no\" class=\"YQ4gaf zr758c wA1Bge\" alt=\"\" data-atf=\"4\" data-frt=\"0\" width=\"92\" height=\"92\"></g-img></a></div></div></div></div>"
bearer_token = 'Huggingface Token or Private Server Key'
result = GoogleLocalResultsAiParser.parse(html: html, bearer_token: bearer_token)
```

<img width="851" alt="image" src="https://user-images.githubusercontent.com/73674035/205724193-917feb92-3054-436d-93e9-552f8ec7ca9b.png">

The result variable will contain a hash with the extracted data classified into different categories. For example:

```rb
{
  "address" => "Nicosia",
  "description" => "Iconic Seattle-based coffeehouse chain",
  "price" => "€€",
  "reviews" => "418",
  "rating" => "4.0",
  "type" => "Coffee shop"
}
```

<h3 align="center">Parsing Multiple HTML Parts</h3>

If you have multiple HTML parts that you want to parse concurrently, you can use the `GoogleLocalResultsAiParser.parse_multiple` method. This method takes an array of HTML parts and returns an array of parsed results:

```rb
html_parts = [
                '<div jscontroller=\"AtSb\" class=\"w7Dbne\" data-record-click-time=\"false\" id=\"tsuid_25\" jsdata=\"zt2wNd;_;BvbRxs V6f1Id;_;BvbRxw\" jsaction=\"rcuQ6b:npT2md;e3EWke:kN9HDb\" data-hveid=\"CBUQAA\"><div jsname=\"jXK9ad\" class=\"uMdZh tIxNaf\" jsaction=\"mouseover:UI3Kjd\"><div class=\"VkpGBb\"><div class=\"cXedhc\"><a class=\"vwVdIc wzN8Ac rllt__link a-no-hover-decoration\" jsname=\"kj0dLd\" data-cid=\"12176489206865957637\" jsaction=\"click:h5M12e;\" role=\"link\" tabindex=\"0\" data-ved=\"2ahUKEwiS1P3_j-P7AhXnVPEDHa0oAiAQvS56BAgVEAE\"><div><div class=\"rllt__details\"><div class=\"dbg0pd\" aria-level=\"3\" role=\"heading\"><span class=\"OSrXXb\">Y Coffee</span></div><div><span class=\"Y0A0hc\"><span class=\"yi40Hd YrbPuc\" aria-hidden=\"true\">4.0</span><span class=\"z3HNkc\" aria-label=\"Rated 4.0 out of 5,\" role=\"img\"><span style=\"width:56px\"></span></span><span class=\"RDApEe YrbPuc\">(418)</span></span> · <span aria-label=\"Moderately expensive\" role=\"img\">€€</span> · Coffee shop</div><div>Nicosia</div><div class=\"pJ3Ci\"><span>Iconic Seattle-based coffeehouse chain</span></div></div></div></a><a class=\"uQ4NLd b9tNq wzN8Ac rllt__link a-no-hover-decoration\" aria-hidden=\"true\" tabindex=\"-1\" jsname=\"kj0dLd\" data-cid=\"12176489206865957637\" jsaction=\"click:h5M12e;\" role=\"link\" data-ved=\"2ahUKEwiS1P3_j-P7AhXnVPEDHa0oAiAQvS56BAgVEA4\"><g-img class=\"gTrj3e\"><img id=\"pimg_3\" src=\"https://lh5.googleusercontent.com/p/AF1QipPaihclGQYWEJpMpBnBY8Nl8QWQVqZ6tF--MlwD=w184-h184-n-k-no\" class=\"YQ4gaf zr758c wA1Bge\" alt=\"\" data-atf=\"4\" data-frt=\"0\" width=\"92\" height=\"92\"></g-img></a></div></div></div></div>',
                '<div jscontroller=\"AtSb\" class=\"w7Dbne\" data-record-click-time=\"false\" id=\"tsuid_25\" jsdata=\"zt2wNd;_;BvbRxs V6f1Id;_;BvbRxw\" jsaction=\"rcuQ6b:npT2md;e3EWke:kN9HDb\" data-hveid=\"CBUQAA\"><div jsname=\"jXK9ad\" class=\"uMdZh tIxNaf\" jsaction=\"mouseover:UI3Kjd\"><div class=\"VkpGBb\"><div class=\"cXedhc\"><a class=\"vwVdIc wzN8Ac rllt__link a-no-hover-decoration\" jsname=\"kj0dLd\" data-cid=\"12176489206865957637\" jsaction=\"click:h5M12e;\" role=\"link\" tabindex=\"0\" data-ved=\"2ahUKEwiS1P3_j-P7AhXnVPEDHa0oAiAQvS56BAgVEAE\"><div><div class=\"rllt__details\"><div class=\"dbg0pd\" aria-level=\"3\" role=\"heading\"><span class=\"OSrXXb\">X Coffee</span></div><div><span class=\"Y0A0hc\"><span class=\"yi40Hd YrbPuc\" aria-hidden=\"true\">4.0</span><span class=\"z3HNkc\" aria-label=\"Rated 4.0 out of 5,\" role=\"img\"><span style=\"width:56px\"></span></span><span class=\"RDApEe YrbPuc\">(418)</span></span> · <span aria-label=\"Moderately expensive\" role=\"img\">€€</span> · Coffee shop</div><div>Nicosia</div><div class=\"pJ3Ci\"><span>Iconic Washington-based coffeehouse chain</span></div></div></div></a><a class=\"uQ4NLd b9tNq wzN8Ac rllt__link a-no-hover-decoration\" aria-hidden=\"true\" tabindex=\"-1\" jsname=\"kj0dLd\" data-cid=\"12176489206865957637\" jsaction=\"click:h5M12e;\" role=\"link\" data-ved=\"2ahUKEwiS1P3_j-P7AhXnVPEDHa0oAiAQvS56BAgVEA4\"><g-img class=\"gTrj3e\"><img id=\"pimg_3\" src=\"https://lh5.googleusercontent.com/p/AF1QipPaihclGQYWEJpMpBnBY8Nl8QWQVqZ6tF--MlwD=w184-h184-n-k-no\" class=\"YQ4gaf zr758c wA1Bge\" alt=\"\" data-atf=\"4\" data-frt=\"0\" width=\"92\" height=\"92\"></g-img></a></div></div></div></div>',
                ...
             ]
bearer_token = 'Huggingface Token or Private Server Key'
results = GoogleLocalResultsAiParser.parse_multiple(html_parts: html_parts, bearer_token: bearer_token)
```

The results variable will contain an array of hashes, with each hash representing the extracted data from a corresponding HTML part:

```rb
[
    {
      "address" => "Nicosia",
      "description" => "Iconic Seattle-based coffeehouse chain",
      "price" => "€€",
      "reviews" => "418",
      "rating" => "4.0",
      "type" => "Coffee shop"
    },
    ...
]
```
---
<h2 align="center">Advanced Usage</h2>

The `google-local-results-ai-parser` gem provides several advanced features to handle different scenarios and improve the accuracy of the parsing results.

<h3 align="center">Configuration Options</h3>

The gem provides some configuration options that you can customize according to your needs:
- `server`: The API server URL for the Hugging Face model. The default value is [`https://api-inference.huggingface.co/models/serpapi/bert-base-local-results`](https://api-inference.huggingface.co/models/serpapi/bert-base-local-results). You may change the value to your desired endpoint.
    - **Free Inference API**: This default endpoint is a Free Inference API for `Fast Prototyping` offered by Huggingface. It might not be up all the time, or could get rate-limited depending on your usage. You may find the relevant information about Free Inference API at [Huggingface Documentation](https://huggingface.co/docs/api-inference/index).
    - **Production-Ready Inference API Endpoints**: For `Production` or `Heavy-Load Prototyping`, one of the options is to set up your Private Production-Ready Inference API Endpoints from [`serpapi/bert-base-local-results` Repository Page](https://huggingface.co/serpapi/bert-base-local-results). You may find the relevant information about Production-Ready Inference API Endpoints at [Huggingface Documentation](https://huggingface.co/docs/inference-endpoints/index).
    - **Private Server**: Another option for `Production` or `Heavy-Load Prototyping` is setting up your Private Server that mimics the Production-Ready Inference API. [SerpApi](https://serpapi.com) has open-sourced an example server code called [` google-local-results-ai-server`](https://github.com/serpapi/google-local-results-ai-server). The default path to make POST Requests  will be at `/models/serpapi/bert-base-local-results` once you deploy or locally set up the private server.

- `separator_regex`: A regular expression used to split the extracted text into separate parts. The default value is `/\n|·|⋅/`. This ruby regex is splitting the text where they are separated in a Google Local Result. The default value is enough for recent results, and may be changed in the future if the text structure at Google Local Results changes.

- `rejected_css`: CSS selector to exclude specific elements from the parsing process. The default value is `"[role='heading'], a[ping], [class*='label']"`. These CSS selectors contain titles, links, and labels which are excluded from the parser due to their easy-to-scrape nature. Any enrichment to these CSS selectors should be done according to [`Nokolexbor`](https://github.com/serpapi/nokolexbor) standards. [`Nokolexbor`](https://github.com/serpapi/nokolexbor) is a drop-in replacement for Nokogiri. It's 5.2x faster at parsing HTML and up to 997x faster at CSS selectors.

- `broken_css`: CSS selector to break down bold text and reduce noise. The default value is `"b:has(::text)"`. The default value is enough to break down elements that create a noise for the model by extracting different parts of the same text as separate items for recent results. It may be changed in the future if the HTML structure of the Google Local Results changes. Any enrichment to these CSS selectors should be done according to [`Nokolexbor`](https://github.com/serpapi/nokolexbor) standards as well.

- `iteration`: The maximum number of iterations for after-corrections. The default value is `1`. The gem uses after-corrections to model's predictions to serve more precise results. You may find the known limitations at the [`serpapi/bert-base-local-results`](https://huggingface.co/serpapi/bert-base-local-results). The 3 types of after-corrections are:
    - **Safety measures**: Safety measures are for protecting against the noise of the unpredicted cases. For now, there is only one kind of safety measure in the gem, and that is checking if an excerpt button text has been caught and deducted from the result. The button texts are handled by the traditional part of SerpApi's Google Local API, and should be deducted if caught.
    - **Known clashes**: Sometimes the model serves clashing results for one label. This may happen due to limitations of the model, the generality of meaning of the classified text, or the limitations of the dataset model was trained on. The gem can clear out the majority of the known clashes, and correct them using traditional logical algorithms.
    - **General clashes**: The model can compare the assurance score of two texts with same label, and pick the one with a higher score to automatically correct the results after predictions. From raw observations, doing after-corrections only once is observed to be enough. You may increase `iteration` parameter to force the after-corrections more in case of any further clashes.


[gem-shield]: https://img.shields.io/gem/v/google-local-results-ai-parser.svg
[gem-url]: https://rubygems.org/gems/google-local-results-ai-parser
[contributors-shield]: https://img.shields.io/github/contributors/serpapi/google-local-results-ai-parser.svg
[contributors-url]: https://github.com/serpapi/google-local-results-ai-parser/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/serpapi/google-local-results-ai-parser.svg
[forks-url]: https://github.com/serpapi/google-local-results-ai-parser/network/members
[stars-shield]: https://img.shields.io/github/stars/serpapi/google-local-results-ai-parser.svg
[stars-url]: https://github.com/serpapi/google-local-results-ai-parser/stargazers
[issues-shield]: https://img.shields.io/github/issues/serpapi/google-local-results-ai-parser.svg
[issues-url]: https://github.com/serpapi/google-local-results-ai-parser/issues
[issuesclosed-shield]: https://img.shields.io/github/issues-closed/serpapi/google-local-results-ai-parser.svg
[issuesclosed-url]: https://github.com/serpapi/google-local-results-ai-parser/issues?q=is%3Aissue+is%3Aclosed
[license-shield]: https://img.shields.io/github/license/serpapi/google-local-results-ai-parser.svg
[license-url]: https://github.com/serpapi/google-local-results-ai-parser/blob/master/LICENSE
