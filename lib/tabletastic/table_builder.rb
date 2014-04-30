require File.join(File.dirname(__FILE__), 'table_field')

module Tabletastic
  class TableBuilder
    @@default_hidden_columns = %w[created_at updated_at created_on updated_on lock_version version]
    @@destroy_confirm_message = "Are you sure?"

    attr_reader   :collection, :klass, :table_fields

    def initialize(collection, klass, template)
      @collection, @klass, @template = collection, klass, template
      @table_fields = []
    end

    # builds up the fields that the table will include,
    # returns table head and body with all data
    #
    # Can be used one of three ways:
    #
    # * Alone, which will try to detect all content columns on the resource
    # * With an array of methods to call on each element in the collection
    # * With a block, which assumes you will use +cell+ method to build up
    #   the table
    #
    def data(*args, &block) # :yields: tablebody
      options = args.extract_options!
      if block_given?
        yield self
      else
        @table_fields = args.empty? ? orm_fields : args.collect {|f| TableField.new(f.to_sym)}
      end
      action_cells(options[:actions], options[:action_prefix])
      ["\n", head, "\n", body, "\n"].join("").html_safe
    end

    # individually specify a column, which will build up the header,
    # and method or block to call on each resource in the array
    #
    # Should always be called within the block of +data+
    #
    # For example:
    #
    #   t.cell :blah
    #
    # will simply call +blah+ on each resource
    #
    # You can also provide a block, which allows for other helpers
    # or custom formatting. Since by default erb will just call +to_s+
    # on an any element output, you can more greatly control the output:
    #
    #   t.cell(:price) {|resource| number_to_currency(resource)}
    #
    # would output something like:
    #
    #   <td>$1.50</td>
    #
    def cell(*args, &proc)
      options = args.extract_options!
      options.merge!(:klass => klass, :template => @template)
      args << options
      @table_fields << TableField.new(*args, &proc)
      # Since this will likely be called with <%= %> (aka 'concat'), explicitly return an 
      # empty string; this suppresses unwanted output
      return ""
    end

    def head
      content_tag(:thead) do
        content_tag(:tr) do
          @table_fields.inject("") do |result,field|
            result + content_tag(:th, field.heading, field.heading_html)
          end.html_safe
        end
      end
    end

    def body
      content_tag(:tbody) do
        @collection.inject("\n") do |rows, record|
          rowclass = @template.cycle("odd","even")
          rows += @template.content_tag_for(:tr, record, :class => rowclass) do
            cells_for_row(record)
          end + "\n"
        end.html_safe
      end
    end

    def cells_for_row(record)
      @table_fields.inject("") do |cells, field|
        cells + content_tag(:td, field.cell_data(record), field.cell_html)
      end.html_safe
    end

    # Used internally to build up cells for common CRUD actions
    def action_cells(actions, prefix = nil)
      return if actions.blank?
      actions = [actions] if !actions.respond_to?(:each)
      actions = [:show, :edit, :destroy] if actions == [:all]
      actions.each do |action|
        action_link(action.to_sym, prefix)
      end
    end

    # Dynamically builds links for the action
    def action_link(action, prefix)
      html_class = "actions #{action.to_s}_link"
      block = lambda do |resource|
        compound_resource = [prefix, resource].compact
        compound_resource.flatten! if prefix.kind_of?(Array)
        case action
        when :show
          @template.link_to(link_title(action), compound_resource)
        when :destroy
          @template.link_to(link_title(action), compound_resource,
                            :method => :delete, :data => { :confirm => confirmation_message })
        else # edit, other resource GET actions
          @template.link_to(link_title(action),
                            @template.polymorphic_path(compound_resource, :action => action))
        end
      end
      self.cell(action, :heading => "", :cell_html => {:class => html_class}, &block)
    end

    protected

    def orm_fields
      return [] if klass.blank?
      fields = if klass.respond_to?(:content_columns)
        active_record_fields
      elsif klass.respond_to?(:fields)
        mongoid_fields
      else
        []
      end
      fields -= @@default_hidden_columns
      fields.collect {|f| TableField.new(f.to_sym)}
    end

    private

    def mongoid_fields
      klass.fields.keys
    end

    def active_record_fields
      klass.content_columns.map(&:name) + active_record_association_reflections
    end

    def active_record_association_reflections
      return [] unless klass.respond_to?(:reflect_on_all_associations)
      associations = []
      associations += klass.reflect_on_all_associations(:belongs_to).map(&:name)
      associations += klass.reflect_on_all_associations(:has_one).map(&:name)
      associations
    end

    def confirmation_message
      I18n.t("tabletastic.actions.confirmation", :default => @@destroy_confirm_message)
    end

    def content_tag(name, content = nil, options = nil, escape = true, &block)
      @template.content_tag(name, content, options, escape, &block)
    end

    def link_title(action)
      I18n.translate(action, :scope => "tabletastic.actions", :default => action.to_s.titleize)
    end
  end
end
