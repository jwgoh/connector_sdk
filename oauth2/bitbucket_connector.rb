{
    title: 'Bitbucket',
    connection: {

      authorization: {
        type: 'oauth2',
        authorization_url: ->() {
         	'https://bitbucket.org/site/oauth2/authorize?response_type=code&scope=issue:write'
        },

        token_url: ->() {
         	'https://bitbucket.org/site/oauth2/access_token?grant_type=refresh'
        },

        client_id: 'L9QZ4zTGM2HGRvk4Mt',

        client_secret: 'DEqy8WhBn2v7mrNuUk33BufyJnUbSmH4',

        credentials: ->(connection, access_token) {
        	headers('Authorization': "Bearer #{access_token}")
        }
      }
    },

    test: ->(connection) {    
      get("https://api.bitbucket.org/2.0/user")
    },

    object_definitions: {   
      issue: {
        fields: ->(connection, config) {
          [
            { name: "username", optional: false, hint: "Username", label: "Repository owner" },
            { name: "repo_slug", optional: false, label: "Repository slug", hint: 'Can be found at the end of url in repository page' },
            { name: "title", optional: false, label: "Title" },
            { name: "priority", optional: false, hint: 'Possible values are trivial, minor, major, critical, blocker', label: "Priority" },
            { name: "kind", optional: false, hint: 'Possible values are bug, enhancement, proposal, task', label: "Kind" },
            { name: "description", label: "Description" },
            { name: "componentid",label: "Component", hint: "Enter valid component values" },
            { name: "milestoneid",label: "Milestone", hint: "Enter valid milestone values" },
            { name: "versionid",label: "Version", hint: "Enter valid version values" },
            { name: "assigneeid", label: "Assignee", hint: "Username of assignee" },
            { name: "repository", type: :object, properties:[
              { name: "links", type: :object, properties: [
                { name: "self", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
                { name: "html", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
                { name: "avatar", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
              ] },
              { name: "type" },
              { name: "name" },
              { name: "full_name" },
              { name: "uuid" }
            ] },
            { name: "links", type: :object, properties: [
              { name: "self", type: :object, properties: [
                { name: "href", type: :url }
              ] }
            ] },
            { name: "reporter", type: :object, properties: [
              { name: "username" },
              { name: "display_name" },
              { name: "type" },
              { name: "uuid" },
              { name: "links", type: :object, properties: [
                { name: "self", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
                { name: "html", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
                { name: "avatar", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
              ] },
            ] },
            { name: "votes", type: :integer },
            { name: "watches", type: :integer },
            { name: "content", type: :object, properties: [
              { name: "raw" },
              { name: "markup", hint: 'Possible values are markdown, creole' },
              { name: "html" }
            ] },
            { name: "assignee", type: :object, properties: [
              { name: "username" },
              { name: "display_name" },
              { name: "type" },
              { name: "uuid" },
              { name: "links", type: :object, properties: [
                { name: "self", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
                { name: "html", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
                { name: "avatar", type: :object, properties: [
                  { name: "href", type: :url }
                ] },
              ] },
            ] },
            { name: "status", control_type: :select, hint: 'Possible values are new, open, resolved, on hold, invalid, duplicate, wontfix, closed' },
            { name: "edited_on", type: :datetime },
            { name: "created_on", type: :datetime },
            { name: "updated_on", type: :datetime },
            { name: "type" },
            { name: "id", type: :integer },
            { name: "links", type: :object, properties: [
              { name: "self", type: :object, properties: [
                { name: "href", type: :url }
              ] },
              { name: "repositories", type: :object, properties: [
                { name: "href", type: :url }
              ] },
              { name: "html", type: :object, properties: [
                { name: "href", type: :url }
              ] },
              { name: "followers", type: :object, properties: [
                { name: "href", type: :url }
              ] },
              { name: "avatar", type: :object, properties: [
                { name: "href", type: :url }
              ] },
              { name: "following", type: :object, properties: [
                { name: "href", type: :url }
              ] }
            ] }
          ]
        }
      } 
    },
    
    actions: {
      create_issue: {
        description: 'Create <span class="provider">issue</span> in <span class="provider">Bitbucket</span>',
        
        config_fields: [
        {
          name: 'username', label: 'Repository owner', optional: false, hint: "Username"
        },
        {
          name: 'repo_slug', label: 'Repo_slug', optional: false,
          control_type: 'select', pick_list: 'repo_slug', hint: "Can be found at the end of url in repository page",
          pick_list_params: { username: 'username' }
        },
      ],

        input_fields: ->(object_definitions) {
          object_definitions['issue'].only('title', 'priority', 'kind', 'componentid', 'milestoneid', 'versionid', 'description', 'assigneeid')
        },

        execute: ->(connection,  input) {
          input["content"] = { "raw" => input.delete("description") } if input["description"].present?
          input["component"] = { "name" => input.delete("componentid") } if input["componentid"].present?
          input["milestone"] = { "name" => input.delete("milestoneid") } if input["milestoneid"].present?
          input["version"] = { "name" => input.delete("versionid") } if input["versionid"].present?
          input["assignee"] = { "username" => input.delete("assigneeid") } if input["assigneeid"].present?
          response = post("https://api.bitbucket.org/2.0/repositories/#{input['username'].downcase}/#{input['repo_slug'].downcase.gsub(/[ ]/,'-')}/issues", input)
        },

        output_fields: ->(object_definitions) {
          object_definitions['issue']
        }
      },
      
      get_issue_by_id: {
        description: 'Get <span class="provider">issue by id</span> in <span class="provider">Bitbucket</span>',

        input_fields: ->(object_definitions) {
          [
            { name: "username", optional: false, hint: "Username", label: "Repository owner" },
            { name: "repo_slug", optional: false, label: "Repository slug", hint: 'Can be found at the end of url in repository page' },
            { name: "id",type: :integer, optional: false, hint: "ID of the issue", label: "Issue ID" }
          ]
        },

        execute: ->(connection,input) {
          get("https://api.bitbucket.org/1.0/repositories/#{input['username'].downcase}/#{input['repo_slug'].downcase.gsub(/[ ]/,'-')}/issues/#{input['id']}" )
        },

        output_fields: ->(object_definitions) {
          object_definitions['issue']
        }
      },
      
      search_issues: {
        description: 'Search <span class="provider">issues</span> in <span class="provider">Bitbucket</span>',

        input_fields: ->(object_definitions) {
          [
            { name: "username", optional: false, hint: "Username", label: "Repository owner" },
            { name: "repo_slug", optional: false, label: "Repository slug", hint: 'Can be found at the end of url in repository page' },
            { name: "title", hint: 'Exact match' },
            { name: "kind", hint: 'Possible values are bug, enhancement, proposal, task' },
            { name: "priority", hint: 'Possible values are trivial, minor, major, critical, blocker' },
            { name: "status", hint: 'Possible values are new, open, resolved, on hold, invalid, duplicate, wontfix, closed' }
          ]
        },

        execute: ->(connection,input) {
          get("https://api.bitbucket.org/1.0/repositories/#{input.delete('username')}/#{input['repo_slug'].downcase.gsub(/[ ]/,'-')}/issues", input )
        },

        output_fields: ->(object_definitions) {
          object_definitions['issue']
        }
      },
      
      list_comments_in_an_issue: {
        description: 'List <span class="provider">comments</span> in an issue in <span class="provider">Bitbucket</span>',

        input_fields: ->(object_definitions) {
          [
            { name: "username", optional: false, hint: "Username", label: "Repository owner" },
            { name: "repo_slug", optional: false, label: "Repository slug", hint: 'Can be found at the end of url in repository page' },
            { name: "issue_id", type: :integer, optional: false, hint: "Found in URL of issue page" }
          ]
        },

        execute: ->(connection,input) {
          get("https://api.bitbucket.org/2.0/repositories/#{input['username'].downcase}/#{input['repo_slug'].downcase.gsub(/[ ]/,'-')}/issues/#{input['issue_id']}/comments")
        },

        output_fields: ->(object_definitions) {
          [
            { name: "id", type: :integer },
            { name: "links", type: :object, properties:[
              { name: "self", type: :object, properties:[
                { name: "href", type: :url }
              ]}
            ]}
          ]
        }
      },
    },
    
    triggers: {
      new_or_updated_issue: {
        description: 'New or updated <span class="provider">issue</span> in <span class="provider">Bitbucket</span>',

        type: :paging_desc,

        input_fields: ->() {
          [
            { name: "username", optional: false, hint: "Username", label: "Repository owner" },
            { name: "repo_slug", optional: false, label: "Repository slug", hint: 'Can be found at the end of url in repository page' },
            { name: "since", type: :timestamp, hint: 'Get issues created/updated since the given date/time. Leave empty to get issues created/updated since recipe started', label: "Since" }
          ]
        },

        poll: ->(connection, input, next_page) {
          if next_page.present?
            page = next_page[0]
            updated_date = next_page[1]
          end

          if page.present?
            response = get(page)
          else
            updated_since = (updated_date || input['since'] || Time.now).to_time.utc.strftime("%Y-%m-%dT%H:%M:%S")
            response = get("https://api.bitbucket.org/2.0/repositories/#{input['username'].downcase}/#{input['repo_slug'].downcase.gsub(/[ ]/,'-')}/issues?q=updated_on>#{updated_since}&sort=-updated_on")
          end
          next_updated_since = response['values'].last['updated_on'] unless response['values'].blank?   

          {
            events: response['values'],
            next_page: [response['next'], Time.now]
          }
        },

        document_id: ->(issue){
          issue['document_id']
        },

        sort_by: ->(issue) {
          issue['updated_on']
        },

        output_fields: ->(object_definitions) {
          object_definitions['issue']
        },
      }, 
    },
    
    pick_lists: {
    	repo_slug: ->(connection, username:) {
      	url = "https://api.bitbucket.org/2.0/repositories/#{username}"
      	get(url)['values'].map do |type|
        	[type['name'], type['name'].downcase.gsub(/[ ]/,'-')]
      	end
    	},
    }
  }