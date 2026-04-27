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

      def allowed_includes_list = @allowed_includes

      def apply_include(params = {}, options = { allowed: [] })
        records = all
        fields = params.dig(:include).to_s

        return records if fields.blank?

        allowed_fields = (Array.wrap(options[:allowed]).presence || @allowed_includes).map(&:to_s)

        a_fields = fields.split(',')
        a_fields.each do |field|
          raise InvalidAttributeError, "#{field} is not valid as include attribute." unless allowed_fields.include?(field)
        end

        preload_fields = a_fields.select { |field| reflect_on_association(field)&.polymorphic? }
        include_fields = a_fields - preload_fields
        records = records.includes(convert_includes_as_hash(include_fields.join(',')))
        records.preload(convert_includes_as_hash(preload_fields.join(',')))
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
