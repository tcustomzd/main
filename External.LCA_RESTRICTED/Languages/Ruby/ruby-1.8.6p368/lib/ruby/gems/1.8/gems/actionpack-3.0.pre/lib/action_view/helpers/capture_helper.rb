module ActionView
  module Helpers
    # CaptureHelper exposes methods to let you extract generated markup which
    # can be used in other parts of a template or layout file.
    # It provides a method to capture blocks into variables through capture and 
    # a way to capture a block of markup for use in a layout through content_for.
    module CaptureHelper
      # The capture method allows you to extract part of a template into a 
      # variable. You can then use this variable anywhere in your templates or layout. 
      # 
      # ==== Examples
      # The capture method can be used in ERb templates...
      # 
      #   <% @greeting = capture do %>
      #     Welcome to my shiny new web page!  The date and time is
      #     <%= Time.now %>
      #   <% end %>
      #
      # ...and Builder (RXML) templates.
      # 
      #   @timestamp = capture do
      #     "The current timestamp is #{Time.now}."
      #   end
      #
      # You can then use that variable anywhere else.  For example:
      #
      #   <html>
      #   <head><title><%= @greeting %></title></head>
      #   <body>
      #   <b><%= @greeting %></b>
      #   </body></html>
      #
      def capture(*args, &block)
        # Return captured buffer in erb.
        if block_called_from_erb?(block)
          with_output_buffer { block.call(*args) }
        else
          # Return block result otherwise, but protect buffer also.
          with_output_buffer { return block.call(*args) }
        end
      end

      # Calling content_for stores a block of markup in an identifier for later use.
      # You can make subsequent calls to the stored content in other templates or the layout
      # by passing the identifier as an argument to <tt>yield</tt>.
      # 
      # ==== Examples
      # 
      #   <% content_for :not_authorized do %>
      #     alert('You are not authorized to do that!')
      #   <% end %>
      #
      # You can then use <tt>yield :not_authorized</tt> anywhere in your templates.
      #
      #   <%= yield :not_authorized if current_user.nil? %>
      #
      # You can also use this syntax alongside an existing call to <tt>yield</tt> in a layout.  For example:
      #
      #   <%# This is the layout %>
      #   <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      #   <head>
      #	    <title>My Website</title>
      #	    <%= yield :script %>
      #   </head>
      #   <body>
      #     <%= yield %>
      #   </body>
      #   </html>
      #
      # And now, we'll create a view that has a content_for call that
      # creates the <tt>script</tt> identifier.
      #
      #   <%# This is our view %>
      #   Please login!
      #
      #   <% content_for :script do %>
      #     <script type="text/javascript">alert('You are not authorized to view this page!')</script>
      #   <% end %>
      #
      # Then, in another view, you could to do something like this:
      #
      #   <%= link_to_remote 'Logout', :action => 'logout' %>
      #
      #   <% content_for :script do %>
      #     <%= javascript_include_tag :defaults %>
      #   <% end %>
      #
      # That will place <script> tags for Prototype, Scriptaculous, and application.js (if it exists)
      # on the page; this technique is useful if you'll only be using these scripts in a few views.
      #
      # Note that content_for concatenates the blocks it is given for a particular
      # identifier in order. For example:
      #
      #   <% content_for :navigation do %>
      #     <li><%= link_to 'Home', :action => 'index' %></li>
      #   <% end %>
      #
      #   <%#  Add some other content, or use a different template: %>
      # 
      #   <% content_for :navigation do %>
      #     <li><%= link_to 'Login', :action => 'login' %></li>
      #   <% end %>
      #
      # Then, in another template or layout, this code would render both links in order:
      #
      #   <ul><%= yield :navigation %></ul>
      #
      # Lastly, simple content can be passed as a parameter:
      #
      #   <% content_for :script, javascript_include_tag(:defaults) %>
      #
      # WARNING: content_for is ignored in caches. So you shouldn't use it
      # for elements that will be fragment cached.
      def content_for(name, content = nil, &block)
        content = capture(&block) if block_given?
        return @_content_for[name] << content if content
        @_content_for[name]
      end

      # content_for? simply checks whether any content has been captured yet using content_for
      # Useful to render parts of your layout differently based on what is in your views.
      # 
      # ==== Examples
      #
      # Perhaps you will use different css in you layout if no content_for :right_column
      #
      #   <%# This is the layout %>
      #   <html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
      #   <head>
      #	    <title>My Website</title>
      #	    <%= yield :script %>
      #   </head>
      #   <body class="<%= content_for?(:right_col) ? 'one-column' : 'two-column' %>">
      #     <%= yield %>
      #     <%= yield :right_col %>
      #   </body>
      #   </html>
      def content_for?(name)
        @_content_for[name].present?
      end

      # Use an alternate output buffer for the duration of the block.
      # Defaults to a new empty string.
      def with_output_buffer(buf = nil) #:nodoc:
        unless buf
          buf = ActionView::SafeBuffer.new
          buf.force_encoding(output_buffer.encoding) if buf.respond_to?(:force_encoding)
        end
        self.output_buffer, old_buffer = buf, output_buffer
        yield
        output_buffer
      ensure
        self.output_buffer = old_buffer
      end

      # Add the output buffer to the response body and start a new one.
      def flush_output_buffer #:nodoc:
        if output_buffer && !output_buffer.empty?
          response.body_parts << output_buffer
          new = ''
          new.force_encoding(output_buffer.encoding) if new.respond_to?(:force_encoding)
          self.output_buffer = new
          nil
        end
      end
    end
  end
end