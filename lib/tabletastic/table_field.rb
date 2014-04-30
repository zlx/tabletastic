require 'active_support/core_ext/object'

module Tabletastic
  class TableField
    @@association_methods = %w[to_label display_name full_name name title username login value to_str to_s]

    attr_reader :method, :method_or_proc, :cell_html, :heading_html, :klass

    def initialize(*args, &proc)
      options = args.extract_options!
      @method = args.first.to_sym
      @method_or_proc = block_given? ? proc : method
      @cell_html, @heading_html = options[:cell_html], (options[:heading_html]||{}).merge({width: options.delete(:width)})
      @klass = options.delete(:klass)
      @heading = options.delete(:heading) || default_heading
      @sort = options.delete(:sort) || default_sort
      @template = options.delete(:template)
    end

    def heading
      if @sort
        heading_with_sort
      else
        @heading
      end
    end

    def cell_data(record)
      # Get the attribute or association in question
      result = send_or_call(record, method_or_proc)
      # If we already have a string, just return it
      return result if result.is_a?(String)

      # If we don't have a string, its likely an association
      # Try to detect which method to use for stringifying the attribute
      to_string = detect_string_method(result)
      result.send(to_string) if to_string
    end

    private

    def default_heading
      I18n.translate(method, :scope => i18n_scope, :default => klass_default_heading)
    end

    def default_sort
      false
    end

    def heading_with_sort
      if params[:q] && params[:q][:s]
        prev_attr, prev_dir = params[:q][:s].split(" ")
      end

      current_dir = prev_attr == @method.to_s ? prev_dir : nil
      new_dir = if current_dir
        current_dir == 'desc' ? 'asc' : 'desc'
      else
        'asc'
      end

      html_options = {}
      html_options[:class] = ['sort_link', current_dir].compact.join(' ')

      query_hash = {}
      query_hash[:q] = (params[:q]||{}).with_indifferent_access.merge(s: "#{@method} #{new_dir}")
      options_for_url = params.merge(query_hash)
      binding.pry
      @template.link_to(
        [default_heading, order_indicator_for(current_dir)]
          .compact
          .join(' ')
          .html_safe,
        @template.url_for(options_for_url),
        html_options
        )
    end

    def params
      @template.params
    end

    def order_indicator_for order
      if order == 'asc'
        '&#9650;'
      elsif order == 'desc'
        '&#9660;'
      else
        nil
      end
    end

    def klass_default_heading
      if klass.respond_to?(:human_attribute_name)
        klass.human_attribute_name(method.to_s)
      else
        method.to_s.humanize
      end
    end

    def i18n_scope
      [:tabletastic, :models, klass.try(:model_name).try(:singular)].compact
    end

    def detect_string_method(association)
      @@association_methods.detect { |method| association.respond_to?(method) }
    end

    def send_or_call(object, duck)
      if duck.respond_to?(:call)
        duck.call(object)
      else
        object.send(duck)
      end
    end
  end
end
