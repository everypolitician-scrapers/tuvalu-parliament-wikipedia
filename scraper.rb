#!/bin/env ruby
# encoding: utf-8

require 'scraperwiki'
require 'nokogiri'
require 'open-uri'
require 'colorize'

require 'pry'
require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    self.gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
  # Nokogiri::HTML(open(url).read, nil, 'utf-8')
end

def scrape_term(t)
  noko = noko_for(t[:source])
  noko.css('a[href*="Symbol_confirmed"]').each do |a|
    tds = a.xpath('ancestor::tr/td')
    area = a.xpath('ancestor::table//th[contains(.,"constituency results")]/a').text
    area_id = 'ocd-division/country:tv/constituency:%s' % area.downcase.tr(' ','-')
    who = tds[1].css('a[href*="/wiki/"]')

    data = { 
      name: who.text,
      wikiname: who.attr('title').text,
      area: area,
      area: area_id,
      term: t[:id],
      source: t[:source]
    }
    puts data
  # ScraperWiki.save_sqlite([:id, :term], data)
  end
end

terms = [
  { 
    id: 11,
    name: '11th Parliament',
    start_date: '2015-03-31',
    source: 'https://en.wikipedia.org/wiki/Tuvaluan_general_election,_2015',
  },
  { 
    id: 10,
    name: '10th Parliament',
    start_date: '2010-09-16',
    end_date: '2015-03-30',
    source: 'https://en.wikipedia.org/wiki/Tuvaluan_general_election,_2010',
  },
  { 
    id: 9,
    name: '9th Parliament',
    start_date: '2006-08-03',
    end_date: '2010-09-16',
    source: 'https://en.wikipedia.org/wiki/Tuvaluan_general_election,_2006',
  },
]
# ScraperWiki.save_sqlite([:id], terms, 'terms')

terms.each { |t| scrape_term(t) }

