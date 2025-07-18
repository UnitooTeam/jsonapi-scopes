# frozen_string_literal: true

module Jsonapi
  module Include
    extend ActiveSupport::Concern

    included do
      @allowed_includes ||= []
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

        fields.split(',').each do |field|
          raise InvalidAttributeError, "#{field} is not valid as include attribute." unless allowed_fields.include?(field)
        end

        preloaded_fields = fields & allowed_preloades
        included_fields = ( fields - preloaded_fields ) & allowed_includes

        records
          .includes(convert_includes_as_hash(included_fields))
          .preload(convert_includes_as_hash(preluded_fields))
      end

      private

      def convert_includes_as_hash(includes)
        includes.split(',').map(&:squish).each_with_object({}) do |value, hash|
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
