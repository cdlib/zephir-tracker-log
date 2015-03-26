require 'sinatra'
require 'redis'
require 'yaml'
require 'json'

# Sinatra Application Class (Modular Style)
# All application code within this class
class TrackerLog < Sinatra::Base
  get '/log' do
    config = YAML.load_file('config/app.yml')
    redis = Redis.new(:host => config['notifier']['redis_host'], :port => config['notifier']['redis_port'])
    @days = config['log_viewer']['days_back']
  
    i = 0
  
    @dates = {}
  
    while i < @days do
      date = Date.today - i
    
      keys = redis.keys("robo-kat-#{date.to_s} *")
  
      for key in keys do
        entry = JSON.parse(redis.get(key))
      
        if entry['status'] == 'complete'
        
          for ticket in entry['payload'] do
            unless ticket['jira_comment'].nil?
              @dates[date.to_s] = [] if @dates[date.to_s].nil?
            
              @dates[date.to_s] << {:cid => ticket['cid'], 
                                    :items => ticket['id'], 
                                    :ticket => ticket['key'], 
                                    :message => ticket['jira_comment']}
            end
          end
        end
        
      end
    
      i = i + 1
    end
  
    erb :log_viewer
  
  end
end

# Sample log entry in Redis DB

#{"id":"7a0dd1f8-033e-44ae-baef-6b2f3dcb0856",
# "process":"Robo-Kat",
# "status":"complete",
# "time":"2015-02-20 15:12:19 -0800",
# "payload":[{"login":"success"},
#            {"search_results":"Detected 50 open JIRA tickets."},
#            {"jira_comment":"Zephir was unable to locate the digitized volume: https://babel.hathitrust.org/cgi/pt?id=njp.321746 ...",
#             "id":"",
#             "cid":"HTS-106868",
#             "key":""},
#            {"jira_comment":"JIRA Issue: HTS-106807 is missing information! A valid ticket must have a Record URL AND at ...",
#             "id":"",
#             "cid":"HTS-106807",
#             "key":""},
#            {"jira_comment":"Zephir has received and loaded an updated record from UMN for http://catalog.hathitrust.org/Rec ...",
#             "id":"umn.319510000639438",
#             "cid":"000341571",
#             "key":"HTS-106802"},
#            {"jira_comment":"Zephir has received and loaded an updated record from UMN for http://catalog.hathitrust.org/Rec ...",
#             "id":"umn.31951d01078213k, umn.319510024038086, umn.31951002403810j, umn.31951002403806a",
#             "cid":"001375541",
#             "key":"HTS-106794"}],
# "warnings":[]}