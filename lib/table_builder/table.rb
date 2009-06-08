#
# Methods to help with creating standard tables
# Created by Nate Wiger, so ask him...
#
# The table class itself, for rendering stuff with table_for
module TableBuilder
  class Table
    include ::ActionView::Helpers::TagHelper
    include ::ActionView::Helpers::TextHelper
    attr_reader :row_class

    def initialize(options)
      @cols    = options.delete(:cols)
      @cycle   = options.has_key?(:cycle) ? options.delete(:cycle) : true
      @labels  = options.delete(:labels)
      @actions = options.delete(:actions) || options.delete(:controls)
      @widths  = options.delete(:widths)
    end

    # Takes an arbitrary array of arguments, and returns them
    # properly formatted as a table head
    def head(*args)
      return '' unless args
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:class] ||= 'head'
      options[:tag] = 'th'

      # reset @cols if :actions => true
      @cols ||= args.length
      @cols += 1 if @actions

      # Have to splat these back together for the next call
      # (*args = flattens, << = adds to list)
      %Q(<thead class="#{options[:class]}">) + row(*args << options) + '</thead>'
    end

    # Creates a submethod ala form_for and table for the form body
    def body(options={}, &block)
      raise ArgumentError, "Missing block" unless block_given?
      options[:class] ||= 'row'
      concat(tag('tbody', options, true))
      yield
      concat('</tbody>')
    end

    # Takes an arbitrary array of arguments, and joins them into
    # a single table row
    def row(*args)
      return '' unless args
      options = args.last.is_a?(Hash) ? args.pop : {}
      tropts  = {:class => ''}

      # Assume :id => 'whatever' is for tr, not td
      tropts[:id]  = options.delete(:id)
      tropts[:rel] = options.delete(:rel)

      # Pre-catch where ":show" means ":hidden" and ":id"
      show, target = nil, nil
      if show = options.delete(:show)
        target = show.is_a?(ActiveRecord::Base) ? "show_#{show.class.name.to_s.underscore}_#{show.to_param}" : "show_#{show.to_param}"
        options[:id] ||= target
        options[:hidden] = true
        options[:colspan] ||= @cols || 1
        options[:colspan] += 1 if @labels  # catch for :labels
      end

      # Only cycle alternating row colors if the field is NOT hidden
      if options.delete(:hidden)
        options[:style] = 'display:none'
        tropts[:class] = 'details '
      elsif cl = options.delete(:class)
        tropts[:class] = "#{cl} "
      elsif @cycle
        @row_class = cycle('even','odd')
      end

      # Always re-add @row_class, even if :cycle => false, so that nested
      # calls to t.row will inherit the *current* row_class (:cycle) only
      # says whether to continue alternating them.
      tropts[:class] += @row_class if @row_class
      td = options.delete(:tag) || 'td'

      # Now, if we were given :cols to table(), we need to make sure
      # all our rows are the same number of elements
      if @cols && ! options[:colspan]
        cols = @cols

        if args.length > cols
          # shrink down
          while args.length > cols
            tmp = args.pop
            # Have to do it this way to get .to_s
            args[-1] = "#{args[-1]} #{tmp.to_s}"
          end
        else
          # spread out
          args << nil while args.length < cols
        end
      end

      # Catch if left col is labels; ie, for "properties" tables
      output = tag('tr', tropts, true)
      if @labels && ! show
        output += tag(td, options.merge(:class => 'label'), true) +
                  args.shift + "</#{td}>"
      end

      # Check for any actions on the right side too
      actions = ''
      if @actions
        actions = content_tag td, args.pop.to_s,
                              options.merge(:class => 'actions')
      end

      # Assemble output, tagging each col with the class "col_XX"
      options[:class] += ' ' if options[:class]
      options[:class] ||= ''
      options[:style] += ';' if options[:style]
      options[:style] ||= ''  # must make "" so +width works below
      args[0] ||= ''  # missing row for t.row :show => foo

      # this nasty bit of code takes the width of a column and jams it into
      # the style="" tag, since that's the only place it's obeyed (width=""
      # is ignored by modern browsers)
      c = 0
      output + args.collect {|r|
        width = @widths && @widths[c] ? "width:#{@widths[c]}px" : ''
        c += 1
        content_tag td, r, options.merge(:class => options[:class] + "col_#{c}",
                                         :style => options[:style] + width)
      }.join("\n") + actions + '</tr>'
    end

    # Takes an arbitrary array of arguments, and returns them as a table footer
    def foot(*args)
      return '' unless args
      options = args.last.is_a?(Hash) ? args.pop : {}
      options[:class] ||= 'foot'
      '<tfoot>'+tag('tr', options, true) + '<td>' +
          args.join("</td>\n<td>") + '</td></tr></tfoot>'
    end

    # This returns the caption for a table. Can also create it via
    # table_for :caption => 'Whatever'
    def caption(text, *help)
      text += ' '+help_icon(help) if help
      content_tag 'caption', text
    end
  end
end
