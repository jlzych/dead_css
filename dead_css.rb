#!/usr/bin/env ruby
require 'anemone'
require 'css_parser'
require 'nokogiri'

module DeadCss

  def DeadCss.crawl(url, &block)
    Core.crawl(url, &block)
  end

  def DeadCss.find_selector_usage(url, selector, &block)
    Core.find_selector_usage(url, selector)
  end

  class Core
    def initialize(url)
      @url = url
      @selectors = {}
      @pages = {}

      yield self if block_given?
    end

    def self.crawl(url)
      self.new(url) do |core|
        yield core if block_given?
        core.run
      end
    end

    def run
      css_parser = CssParser::Parser.new

      Anemone.crawl(@url) do |anemone|
        # Exclude non-page files, e.g. images, movies, documents, etc.
        ext = %w(flv swf png jpg gif asx zip rar tar 7z gz jar js css dtd xsd ico raw mp3 mp4 wav wmv ape aac ac3 wma aiff mpg mpeg avi mov ogg mkv mka asx asf mp2 m1v m3u f4v pdf doc xls ppt pps bin exe rss xml)
        anemone.skip_links_like(/\.#{ext.join('|')}$/)

        # anemone.focus_crawl { |page| page.links[0..1] }

        anemone.on_every_page do |page|
          if page.doc
            page_data = { :url => page.url, :stylesheets => [] }

            page.doc.xpath('//link[@rel="stylesheet"]').each do |link|
              options = {}
              uri = link['href']

              if uri.start_with?("/")
                uri = "#{@url}#{link['href']}"
                options = { :base_uri => page.url }
              # need branches for relative, e.g. style.css and ../style.css
              end
              page_data[:stylesheets].push uri

              # Only load the CSS file if it hasn't already been loaded
              if not css_parser.loaded_uris.include?(uri)
                begin
                  css_parser.load_uri!(uri, options)

                rescue => error
                  puts "#{uri}"
                  puts error
                end
              end
            end # end each link loop
            @pages[page.url.request_uri.to_sym] = page_data

            css_parser.each_selector do |selector|
              # Filter out pseudo-selectors (e.g. :focus, ::after, etc.) since
              # they can't ever select anything.
              #
              # Note: consider just removing them, since the preceding part of
              # the selector CAN match elements, and if that doesn't match anything
              # then the entire thing is worthless
              if not selector.include? ":"
                selector_info = @selectors[selector.to_sym] || { :selector => selector, :pages => [] }

                if not selector_info[:pages].include? page.url
                  if page.doc.css(selector).length > 0
                    selector_info[:pages].push("#{page.url}")
                  end
                end

                @selectors[selector.to_sym] = selector_info
              end
            end

          end
        end # end on_every_page

        anemone.after_crawl do |pages|
          unused_selectors = []
          used_selectors = []

          puts "#{@pages.keys.length} pages crawled:"
          @pages.each do |key, page|
            puts "#{page[:url]}"
          end
          puts "\n"

          @selectors.each do |key, selector|
            if selector[:pages].length == 0
              unused_selectors.push selector[:selector]
            else
              used_selectors.push selector[:selector]
            end
          end

          puts "#{unused_selectors.length} Unused Selectors:"
          puts unused_selectors
          puts "\n---\nUsed Selectors:"
          puts used_selectors
        end

      end
    end # run

    def self.find_selector_usage(url, selector)
      Anemone.crawl(url) do |anemone|
        # Exclude non-page files, e.g. images, movies, documents, etc.
        ext = %w(flv swf png jpg gif asx zip rar tar 7z gz jar js css dtd xsd ico raw mp3 mp4 wav wmv ape aac ac3 wma aiff mpg mpeg avi mov ogg mkv mka asx asf mp2 m1v m3u f4v pdf doc xls ppt pps bin exe rss xml)
        anemone.skip_links_like(/\.#{ext.join('|')}$/)

        # anemone.focus_crawl { |page| page.links[0] }

        pages = []
        anemone.on_every_page do |page|
          if page.doc and not pages.include? page.url
            result = page.doc.css selector
            pages.push page.url if result.length > 0
          end
        end

        anemone.after_crawl do |crawled_pages|
          puts "'#{selector}' was found on #{pages.length} of the #{crawled_pages.keys.length} pages crawled."
          puts pages if not pages.empty?
        end
      end # crawl

    end
  end
end

if __FILE__ == $0
  if ARGV.length == 1
    DeadCss.crawl(ARGV[0])
  else
    DeadCss.find_selector_usage(ARGV[0], ARGV[1])
  end
end
