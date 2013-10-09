# encoding: utf-8
require 'virtus'

module CartoDB
  module Synchronization
    class << self
      attr_accessor :repository
    end

    class Member
      include Virtus

      STATES = %w{ enabled disabled }

      attribute :id,              String
      attribute :name,            String
      attribute :interval,        Integer
      attribute :url,             String
      attribute :state,           String
      attribute :user_id,         Integer
      attribute :created_at,      Time
      attribute :updated_at,      Time
      attribute :run_at,          Time
      attribute :runned_at,       Time
      attribute :retried_times,   Integer

      def initialize(attributes={}, repository=Synchronization.repository)
        super(attributes)
        @repository = repository
        self.id     ||= @repository.next_id
        self.state  ||= 'enabled'
      end

      def store
        raise CartoDB::InvalidMember unless self.valid?
        set_timestamps
        repository.store(id, attributes.to_hash)
        self
      end

      def fetch
        data = repository.fetch(id)
        raise KeyError if data.nil?
        self.attributes = data
        self
      end

      def delete
        repository.delete(id)
        self.attributes.keys.each { |key| self.send("#{key}=", nil) }
        self
      end

      def enqueue
        puts "enqueing #{id}"
        Resque.enqueue(Resque::SynchronizationJobs, job_id: id)
      end

      def run
        puts "running #{id}"
        tracker       = lambda { |state| self.state = state; save }
        downloader    = CartoDB::Importer2::Downloader.new(url)
        runner        = CartoDB::Importer2::Runner.new(
                          pg_options, downloader, log, user.remaining_quota
                        )
        database      = user.in_database
        
        importer      = CartoDB::Synchronization::Adapter
                          .new(name, runner, database).run
      end

      def to_hash
        attributes.to_hash
      end

      def to_json(*args)
        attributes.to_json(*args)
      end

      def valid?
        true
      end

      def enabled?
        state == 'enabled'
      end

      def enable
        self.state = 'enabled'
      end

      def disable
        self.state = 'disabled'
      end
      
      def set_timestamps
        self.created_at ||= Time.now.utc
        self.updated_at = Time.now.utc
        self
      end

      def authorize?(user)
        user.id == user_id
      end

      def pg_options
        Rails.configuration.database_configuration[Rails.env].symbolize_keys
          .merge(
            user:     current_user.database_username,
            password: current_user.database_password,
            database: current_user.database_name
          )
      end 

      attr_reader :repository
    end # Member
  end # Synchronization
end # CartoDB
