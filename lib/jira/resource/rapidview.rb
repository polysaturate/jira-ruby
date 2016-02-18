require 'cgi'

module JIRA
  module Resource

    class RapidViewFactory < JIRA::BaseFactory # :nodoc:
    end

    class RapidView < JIRA::Base

      def self.all(client)
        response = client.get(path_base(client) + '/rapidview')
        json = parse_json(response.body)
        json['views'].map do |view|
          client.RapidView.build(view)
        end
      end

      def self.find(client, key, options = {})
        response = client.get(path_base(client) + "/rapidview/#{key}")
        json = parse_json(response.body)
        client.RapidView.build(json)
      end

      def issues
        response = client.get(path_base(client) + "/xboard/plan/backlog/data?rapidViewId=#{id}")
        json = self.class.parse_json(response.body)
        # To get Issue objects with the same structure as for Issue.all
        issue_ids = json['issues'].map { |issue| issue['id'] }
        client.Issue.jql("id IN(#{issue_ids.join(', ')})")
      end

      def sprintquery
        response = client.get(path_base(client) + "/sprintquery/#{id}")
        json = self.class.parse_json(response.body)
        json
      end

      def project
        response = client.get(path_base(client) + "/rapidviewconfig/editmodel.json?rapidViewId=#{id}")
        json = self.class.parse_json(response.body)
        json['filterConfig']['queryProjects']['projects'].first.except('isValidEditProjectConfigAction')
      end

      def backlog
        response = client.get(actual_base(client) +"/rest/agile/1.0/board/#{id}/backlog")
        json = self.class.parse_json(response.body)
        issue_ids = json['issues'].map { |issue| issue['id'] }
        client.Issue.jql("id IN(#{issue_ids.join(', ')})").map(&:attrs)
      rescue JIRA::HTTPError => e
        puts e.inspect
      end

      private

      def self.path_base(client)
        client.options[:context_path] + '/rest/greenhopper/1.0'
      end

      def path_base(client)
        self.class.path_base(client)
      end

      def self.actual_base(client)
        client.options[:context_path]
      end

      def actual_base(client)
        self.class.actual_base(client)
      end

    end

  end
end
