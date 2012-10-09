require 'thor'
require 'thor/actions'

module Jimmy
  class Cli < Thor
    include Thor::Actions

    desc 'create', 'Create and enable new application'
    method_option :name, :type => :string, :banner => 'app_name', :desc => 'Application name', :required => true
    method_option :location, :type => :string, :banner => '/var/apps', :desc => 'Application home directory', :default => '/var/apps'
    method_option :domain, :type => :array, :banner => 'app_name.dev www.app_name.dev', :desc => 'Application domains', :required => true
    method_option :nginx_dir, :type => :string, :banner => '/etc/nginx', :desc => 'Nginx directory', :default => '/etc/nginx'

    def create
      create_app_group
      create_app_user
      init_git_repo
      copy_hooks
      install_nginx
      say "Done, enjoy!", :green
    end

    desc 'destroy', 'Destroy web application'
    method_option :name, :type => :string, :banner => 'app_name', :desc => 'Application name', :required => true
    method_option :nginx_dir, :type => :string, :banner => '/etc/nginx', :desc => 'Nginx directory', :default => '/etc/nginx'
    def destroy
    end

    def self.source_root
      File.expand_path('../templates', __FILE__)
    end

    private
    def create_app_group
      say "Creating application user group #{options[:name]}"
      if run "addgroup --system #{options[:name]}", :capture => true
        say "User group #{options[:name]} created", :green
      else
        say "Cannot create user group #{options[:name]}", :red
        exit 1
      end
    end

    def create_app_user
      say "Creating application user account #{options[:name]}"
      if run "adduser --system --home #{app_path} --shell /usr/bin/git-shell --ingroup #{options[:name]} #{options[:name]}"
        say "User account #{options[:name]} created", :green
      else
        say "Cannot create user account #{options[:name]}", :red
        exit 2
      end
    end

    def init_git_repo
      say "Creating application git repo in #{git_repo_path}"
      if run "sudo -u #{options[:name]} git init #{git_repo_path}"
        say "Git repo #{git_repo_path} created", :green
      else
        say "Cannot create git repo in #{git_repo_path}", :red
        exit 3
      end
    end

    def copy_hooks
      say "Creating application git hooks in #{git_hooks_path}"
      if copy_file("post-receive", File.join(git_hooks_path, 'post-receive')) && copy_file("pre-receive", File.join(git_hooks_path, 'pre-receive'))
        run "cd #{git_repo_path} && sudo -u #{options[:name]} git config receive.denyCurrentBranch ignore"
        run "cd #{git_repo_path} && chown -R #{options[:name]}:#{options[:name]} ."
        run "cd #{git_hooks_path} && chmod +x pre-receive"
        run "cd #{git_hooks_path} && chmod +x post-receive"
        say "Hooks in #{git_hooks_path} created", :green
      else
        say "Cannot create git hooks in #{git_hooks_path}", :red
        exit 4
      end
    end

    def copy_foreman_custom_templates
      say "Copying custom foreman upstart templates to #{home_foreman_path}"
      directory("foreman", home_foreman_path)
    end

    def install_nginx
      say "Installing nginx site in #{nginx_available_sites_path}"
      template("nginx.conf.erb", File.join(nginx_available_sites_path, options[:name]))
      say "Linking nginx site to enabled sites"
      run "cd #{nginx_enabled_sites_path} && sudo ln -s #{File.join(nginx_available_sites_path, options[:name])}"
      say "Reloading nginx"
      run "initctl restart nginx"
    end

    def app_path
      @app_path ||= File.join(options[:location], options[:name])
    end

    def git_repo_path
      @git_repo_path ||= File.join(app_path, 'current')
    end

    def git_hooks_path
      @git_hooks_path ||= File.join(git_repo_path, '.git', 'hooks')
    end

    def nginx_enabled_sites_path
      @nginx_enabled_sites_path ||= File.join(options[:nginx_dir], 'sites-enabled')
    end

    def home_foreman_path
      @home_foreman_path ||= File.join(app_path, '.foreman')
    end

    def nginx_available_sites_path
      @nginx_available_sites_path ||= File.join(options[:nginx_dir], 'sites-available')
    end

    def domains
      @domains ||= options[:domain].join(' ')
    end

    def socket_path
      @socket_path ||= File.join(git_repo_path, 'tmp', 'web.sock')
    end
  end
end
