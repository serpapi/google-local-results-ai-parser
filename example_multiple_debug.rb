require './lib/google-local-results-ai-parser'

html_parts = [
  '<div jscontroller="AtSb" class="w7Dbne CR1S4b" data-record-click-time="false" id="tsuid_38" jsdata="zt2wNd;_;B40xrM WDO8Ff;_;B40xrY" jsaction="rcuQ6b:npT2md;e3EWke:kN9HDb" data-hveid="CBgQAA"><div jsname="jXK9ad" class="uMdZh tIxNaf rllt__borderless" jsaction="mouseover:UI3Kjd;mouseleave:Tx5Rb"><div class="VkpGBb"><div class="cXedhc"><a class="vwVdIc wzN8Ac rllt__link a-no-hover-decoration" jsname="kj0dLd" data-cid="6125476509096315320" jsaction="click:h5M12e;" role="link" tabindex="0" data-ved="2ahUKEwjGmqav77v_AhVPcvEDHe0ABA4Q1YkKegQIGBAB"><div><div class="rllt__details"><div class="dbg0pd" aria-level="3" role="heading"><span class="OSrXXb">Gustav Roasting Co.</span></div><div><span><span class="Y0A0hc"><span class="yi40Hd YrbPuc" aria-hidden="true">4.8</span><span class="z3HNkc" aria-label="Rated 4.8 out of 5," role="img"><span style="width:70px"></span></span><span class="RDApEe YrbPuc">(64)</span></span></span> · Coffee shop</div><div>Mehmet Akif Caddesi No:112</div><div class="dXnVAb"><span class="BI0Dve"><span><span aria-label="Takeaway">Takeaway</span></span><span class="if66xd">·</span></span><span class="BI0Dve"><span><span aria-label="No dine-in">No dine-in</span></span><span class="if66xd">·</span></span><span class="BI0Dve"><span><span aria-label="No delivery">No delivery</span></span></span></div></div></div></a><a class="uQ4NLd b9tNq wzN8Ac rllt__link a-no-hover-decoration" aria-hidden="true" tabindex="-1" jsname="kj0dLd" data-cid="6125476509096315320" jsaction="click:h5M12e;" role="link" data-ved="2ahUKEwjGmqav77v_AhVPcvEDHe0ABA4Q1YkKegQIGBAL"><g-img class="gTrj3e"><img id="pimg_1" src="https://lh5.googleusercontent.com/p/AF1QipMJBSZBgAw-jzVoRZWxuBUixiJJajyJ4ITrtslW=w167-h167-n-k-no" class="YQ4gaf zr758c wA1Bge" alt="" data-atf="4" data-frt="0" width="92" height="92"></g-img></a></div></div></div></div>',
  '<a class="vwVdIc wzN8Ac rllt__link a-no-hover-decoration" jsname="kj0dLd" data-cid="8340045413518965442" jsaction="click:h5M12e;" role="link" tabindex="0" data-ved="2ahUKEwjVnbbfqr3_AhUEZ_EDHWpjALAQyTN6BAgQEAE"><div><div class="rllt__details"><div class="dbg0pd" aria-level="3" role="heading"><span class="OSrXXb">Fusion Kitchen</span></div><div><span><span class="Y0A0hc"><span class="yi40Hd YrbPuc" aria-hidden="true">4.6</span><span class="z3HNkc" aria-label="Rated 4.6 out of 5," role="img"><span style="width:62px"></span></span><span class="RDApEe YrbPuc">(30)</span></span></span> · Fast Food</div><div>Jordan, Hong Kong</div><div><span><b class="Z5bgrc">Takeout</b>: Now ⋅ Ends 10 pm</span></div></div></div></a>',
]
bearer_token = 'Huggingface Token or Private Server Key'
server = 'Server URL' # Without the word Bearer

time_start = Time.now
results_and_time_taken = GoogleLocalResultsAiParser.parse_multiple(html_parts: html_parts, bearer_token: bearer_token, server: server, debug: true, no_cache: true)
time_end = Time.now

puts results_and_time_taken.map{|r| r[0]}
puts "----"
puts "Results"
puts "Total Time Taken: #{time_end - time_start} seconds"
puts "Maximum time taken in parallel requests: #{results_and_time_taken.map{|r| r[1]}.max}"

# This is an example code to show you how you can debug the maximum time it takes to connect
# to server in parallel requests and time it takes to parse. The model is forced to make a
# prediction instead of serving cached results.