# frozen_string_literal: true

module Jsonapi
  module Include
    extend ActiveSupport::Concern

    included do
      @allowed_includes ||= []
      @allowed_preloades ||= []
    end

    module ClassMethods
      def allowed_includes(*fields)
        @allowed_includes = fields
      end

      def allowed_preloades(*fields)
        @allowed_preloades = fields
      end

      def apply_include(params = {}, options = { allowed: [] })
        records = all
        fields = params.dig(:include).to_s

        return records if fields.blank?

        all_allowed_relationships = (@allowed_includes + @allowed_preloades).uniq
        allowed_fields = (Array.wrap(options[:allowed]).presence || all_allowed_relationships).map(&:to_s)

        a_fields = fields.split(',')
        a_fields.each do |field|
          unless allowed_fields.include?(field)
            raise InvalidAttributeError,
                  "#{field} is not valid as include attribute."
          end
        end

        preloaded_fields = (a_fields & @allowed_preloades) || []
        included_fields = (a_fields - preloaded_fields) & @allowed_includes

        records
          .includes(convert_includes_as_hash(included_fields))
          .preload(convert_includes_as_hash(preloaded_fields))
      end

      private

      def convert_includes_as_hash(includes)
        includes.map(&:squish).each_with_object({}) do |value, hash|
          params = value.split('.')
          key = params.first.to_sym
          hash[key] ||= {}

          next if params.size <= 1

          remaining_fields = params[1..-1].join('.')

          hash[key].merge!(convert_includes_as_hash(remaining_fields))
        end
      end
    end
  end
end
