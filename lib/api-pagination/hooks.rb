module ApiPagination
  class Hooks
    def self.init!
      begin; require 'rails'; rescue LoadError; end
      if defined?(ActionController::Base)
        require 'rails/pagination'
        ActionController::Base.send(:include, Rails::Pagination)
      end

      begin; require 'rails-api'; rescue LoadError; end
      if defined?(ActionController::API)
        require 'rails/pagination'
        ActionController::API.send(:include, Rails::Pagination)
      end

      # Kaminari and will_paginate conflict with each other, so we should check
      # to see if either is already active before attempting to load them.
      if defined?(Kaminari) && defined?(WillPaginate::CollectionMethods)
        STDERR.puts <<-EOC
Warning: api-pagination relies on either Kaminari or WillPaginate, but these
gems conflict.  Please ensure only one of them is active at any given time.

EOC
        return
      elsif defined?(Kaminari)
        initialize_kaminari! and return
      elsif defined?(WillPaginate::CollectionMethods)
        initialize_will_paginate! and return
      end
      # If neither is loaded, we can safely attempt these requires.
      unless ApiPagination.paginator == :will_paginate
        begin
          require 'kaminari'
          initialize_kaminari! and return
        rescue LoadError
        end
      end

      begin
        require 'will_paginate'
        initialize_will_paginate! and return
      rescue LoadError
      end

      STDERR.puts <<-EOC
Warning: api-pagination relies on either Kaminari or WillPaginate. Please
install either dependency by adding one of the following to your Gemfile:

gem 'kaminari'
gem 'will_paginate'

EOC
    end

    def self.initialize_kaminari!
      require 'kaminari/models/array_extension'
      ApiPagination.instance_variable_set(:@paginator, :kaminari)
    end

    def self.initialize_will_paginate!
      WillPaginate::CollectionMethods.module_eval do
        def first_page?() !previous_page end
        def last_page?() !next_page end
      end

      ApiPagination.instance_variable_set(:@paginator, :will_paginate)
    end
  end
end

ApiPagination::Hooks.init!
