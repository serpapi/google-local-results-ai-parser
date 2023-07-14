require './lib/google-local-results-ai-parser'

html = '<div class="VkpGBb"><div class="cXedhc"><a class="vwVdIc wzN8Ac rllt__link a-no-hover-decoration" jsname="kj0dLd" data-cid="3982431987169598286" jsaction="click:h5M12e;" role="link" tabindex="0" data-ved="2ahUKEwiyjZWz2L3_AhVyRfEDHX0cB7AQlrABegQIBBAE"><div><div class="rllt__details"><div class="dbg0pd" aria-level="3" role="heading"><span class="OSrXXb">A.D.A. Auto Repair Center</span></div><div><span><span class="Y0A0hc"><span class="yi40Hd YrbPuc" aria-hidden="true">4.9</span><span class="z3HNkc" aria-label="Rated 4.9 out of 5," role="img"><span style="width:70px"></span></span><span class="RDApEe YrbPuc">(29)</span></span></span> · Vehicle repair shop</div><div>30+ years in business · Chilis 18, Nicosia, Cyprus</div><div>Open ⋅ Closes 6:30 pm · 99 857782</div></div></div></a></div><a class="yYlJEf Q7PwXb L48Cpd brKmxb" aria-describedby="tsuid_7" href="https://www.googleadservices.com/pagead/aclk?sa=L&amp;ai=DChcSEwiKrqCz2L3_AhUSydUKHcd_CsUYABAAGgJ3cw&amp;ohost=www.google.com&amp;cid=CAESauD2xDTWkwyZYLj4k4wJQMqIa8OsgCSH_ZtFtUchveo_Se0DYkOBYrvz6g_0igL0zZIhTSFBXYV76Y5WgwxcjvlgFKTql7_YjvY4jVkOgn3AUIGwBdEZ3oO9cT-O9gU4B8fLVw8cMFrimpM&amp;sig=AOD64_3UrhBGCtSgNdtf4HAVNamKS0rgvg&amp;q=&amp;ctype=99&amp;ved=2ahUKEwiyjZWz2L3_AhVyRfEDHX0cB7AQhKwBegQIBBAO&amp;adurl=" data-ved="2ahUKEwiyjZWz2L3_AhVyRfEDHX0cB7AQhKwBegQIBBAO"><div class="wLAgVc"><span class="XBBs5 z1asCe GYDk8c"><svg focusable="false" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"></path></svg></span><div class="BSaJxc">Website</div></div></a><a style="cursor:pointer" data-url="//www.googleadservices.com/pagead/aclk?sa=L&amp;ai=DChcSEwiKrqCz2L3_AhUSydUKHcd_CsUYABABGgJ3cw&amp;ohost=www.google.com&amp;cid=CAESauD2xDTWkwyZYLj4k4wJQMqIa8OsgCSH_ZtFtUchveo_Se0DYkOBYrvz6g_0igL0zZIhTSFBXYV76Y5WgwxcjvlgFKTql7_YjvY4jVkOgn3AUIGwBdEZ3oO9cT-O9gU4B8fLVw8cMFrimpM&amp;sig=AOD64_2KqinRQ9g6leNprF0lTF4Fd9V0Vg&amp;adurl=&amp;ctype=50&amp;q=" href="#" jsaction="trigger.Ez7VMc" tabindex="0" class="yYlJEf VByer Q7PwXb VDgVie brKmxb" aria-describedby="tsuid_7" data-ved="2ahUKEwiyjZWz2L3_AhVyRfEDHX0cB7AQhawBegQIBBAP"><div><span class="TU05kd"></span><div class="UbRuwe">Directions</div></div></a></div>'
bearer_token = 'Huggingface Token or Private Server Key' # Without the word Bearer
server = 'Server URL'

time_start = Time.now
results, time_taken = GoogleLocalResultsAiParser.parse(html: html, bearer_token: bearer_token, server: server, debug: true, no_cache: true)
time_end = Time.now

puts results
puts "----"
puts "Results"
puts "Total Time Taken: #{time_end - time_start} seconds"
puts "Maximum time taken in parallel requests: #{time_taken} seconds}"

# This is an example code to show you how you can debug the time it takes to connect
# to server and time it takes to parse. The model is forced to make a prediction instead
# of serving cached results.