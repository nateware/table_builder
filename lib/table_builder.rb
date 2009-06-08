# TableBuilder is a simple view helper that lets you easily build tables
# Loosely based on the HTML::QuickTable Perl module
module TableBuilder
  # Bigtime table helper that does it all. Stolen from +form_for+ and +fields_for+
  def table(options={}, &block)
    raise ArgumentError, "Missing block" unless block_given?

    # Grab some internal options
    text = options.delete(:caption)
    options[:cellpadding] ||= 0
    options[:cellspacing] ||= 0
    options[:border] ||= 0

    # Create table object to get rid of other special opts
    table = Table.new(options)

    # Wrap a div if we need one
    concat(tag('table', options, true))
    concat("<caption>#{text}</caption>") if text
    yield table
    concat('</table>')
  end
end
