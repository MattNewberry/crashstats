#!/usr/bin/env ruby

require 'rubygems'
require 'mechanize'
require 'json'
require 'optparse'
require 'fileutils'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: crashstats.rb [options] COMMAND (issues|stats)"

  options[:issue_status] = "unresolved"
  opts.on("-i", "--issue-status [STATUS]", "Issue status - unresolved (default), resolved, or all") do |v|
    options[:issue_status] = v
  end

  options[:build] = ""
  opts.on("-b", "--build [BUILD]", "Specify a specific build") do |v|
    options[:build] = v
  end

  options[:email] = ENV["CRASHLYTICS_EMAIL"]
  opts.on("-e", "--email [EMAIL]", "Email used for login, or ENV['CRASHLYTICS_EMAIL']") do |v|
    options[:email] = v
  end

  options[:password] = ENV["CRASHLYTICS_PASSWORD"]
  opts.on("-p", "--password [PASSWORD]", "Password used for login, or ENV['CRASHLYTICS_PASSWORD']") do |v|
    options[:password] = v
  end

  options[:verbose] = false
  opts.on("-v", "--verbose", "Output debug information") do
    options[:verbose] = true
  end

  options[:output] = nil
  opts.on("-o", "--output [FILE]", "File path to write output") do |v|
    options[:output] = v
  end

  options[:pretty_print] = false
  opts.on("-P", "--pretty", "Pretty print JSON ouput") do
    options[:pretty_print] = true
  end

  options[:backtraces] = false
  opts.on("-B", "--backtraces", "Include backtraces with issues") do
    options[:backtraces] = true
  end

  if !options[:email] || !options[:password]
    puts "Missing email or password\n\n"
    puts opts.to_s
    exit
  end

end.parse!

method = ARGV.pop == "stats" ? "stats" : "issues"

class CrashStats
  def initialize(options)
    @options = options
    @per_page = 35
    @base_url = "https://www.crashlytics.com/api/v2/"

    @agent = Mechanize.new
    @agent.request_headers = {"X-CRASHLYTICS-DEVELOPER-TOKEN" => "0bb5ea45eb53fa71fa5758290be5a7d5bb867e77", "Accept" => "application/json"}

    begin
      @agent.post "#{@base_url}/session", {"email" => options[:email], "password" => options[:password]}
    rescue Mechanize::ResponseCodeError => exception
      puts "Invalid login - check your credentials.\n\n"
      exit
    end
  end

  def issues(with_backtraces=false)
    response = []

    apps = @agent.get "#{@base_url}/apps?metrics_status=open"

    JSON.parse(apps.body).each do |app|

      log("\nGetting #{app['name']} (#{app['bundle_identifier']})\n")

      issue_base_url = "#{@base_url}/organizations/#{app['organization_id']}/apps/#{app['id']}/issues"

      app["issues"] = []
      page = 0
      num_pages = 1

      begin
        app_req = @agent.get "#{issue_base_url}.json?build_equals=#{@options[:build]}&status_equals=#{@options[:issue_status]}&event_type_equals=all&page=#{page + 1}"

        if app_req.response['x-crashlytics-level-1-count']
          num_pages = (app_req.response['x-crashlytics-level-1-count'].to_i / @per_page).ceil
        end

        issues = JSON.parse(app_req.body)
        break if issues.empty?

        issues.each do |i|

          issue_req = @agent.get "#{issue_base_url}/#{i['id']}"
          issue = JSON.parse(issue_req.body)

          if issue["title"]
            title_pieces = issue["title"].split(" line ")
            issue["file"] = title_pieces[0]
            issue["line"] = title_pieces[1] if title_pieces[1]
          end

          if issue["subtitle"]
            subtitle_pieces = issue["subtitle"].split(" ")

            rpattern = /[^\w,:_+]/
            issue["class"] = subtitle_pieces[0].gsub!(rpattern, "")
            issue["method"] = subtitle_pieces[1].gsub!(rpattern, "") if subtitle_pieces[1]
          end

          if with_backtraces || @options[:backtraces]
            begin
              backtrace_req = @agent.get "#{issue_base_url}/#{i['id']}/clsessions/#{issue['latest_cls_id']}"
              store_backtrace(app['bundle_identifier'], issue['id'], backtrace_req.body)
            rescue Mechanize::ResponseCodeError => exception
              next
            end
          end

          log(".")
          app["issues"] << issue
        end

        page += 1

        response << app
      end until page >= num_pages
    end
  end

  def stats
    apps = issues(false)

    stats = []

    apps.each do |app|
      data = {"name" => app["bundle_identifier"]}
      files = {}

      app["issues"].each do |issue|
        name = issue["file"]
        method_name = issue["method"]
        files[name] = {"count" => 0,"methods" => {}} unless files[name]
        files[name]["count"] = files[name]["count"] + issue["crashes_count"]

        methods = files[name]["methods"]
        methods[method_name] = 0 unless methods[method_name]
        methods[method_name] = methods[method_name] + issue["crashes_count"]

        files[name]["methods"] = Hash[methods.sort_by{|k,v| v}.reverse]
      end

      data["files"] = files.sort_by {|_, value| value["count"]}.reverse
      stats << data
    end

    stats
  end

  private
  def log(text)
    print text if @options[:verbose]
  end

  def store_backtrace(bundle_identifier, issue_id, backtrace)
    dir = "backtraces/#{bundle_identifier}"
    FileUtils.mkdir_p(dir) unless File.directory?(dir)
    open("#{dir}/#{issue_id}.txt", "w") { |io| io.write backtrace }
  end
end

c = CrashStats.new(options)
result = c.send(method)
output = options[:pretty_print] ? JSON.pretty_generate(result) : JSON.generate(result)

if (options[:output])
  open(options[:output], "w") { |f|
    f.puts output
  }
else
  puts output
end
