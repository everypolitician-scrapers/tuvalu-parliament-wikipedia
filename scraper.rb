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

def date_from(str)
  return if str.to_s.empty?
  return Date.parse(str).to_s
end

def noko_for(url)
  warn url
  Nokogiri::HTML(open(url).read)
  # Nokogiri::HTML(open(url).read, nil, 'utf-8')
end

def area_id(area)
  'ocd-division/country:tv/constituency:%s' % area.downcase.tr(' ','-')
end

def scrape_term(t, changes)
  noko = noko_for(t[:source])
  noko.css('a[href*="Symbol_confirmed"]').each do |a|
    tds = a.xpath('ancestor::tr/td')
    area = a.xpath('ancestor::table//th[contains(.,"constituency results")]/a').text
    who = tds[1].css('a[href*="/wiki/"]')

    data = { 
      name: who.text,
      wikiname: who.attr('title').text,
      area: area,
      area_id: area_id(area),
      term: t[:id],
      source: t[:source]
    }
    if (change = changes.find { |c| c[:term] == data[:term] && c[:area] == data[:area] && c[:replaced] == data[:name] })
      data[:end_date] = change[:start_date]
      data = [ data, change ]
    end
    ScraperWiki.save_sqlite([:name, :term], data)
  end
end

def scrape_byelections(url)
  noko = noko_for(url)
  noko.xpath('//h2[contains(.,"Tenth Parliament")]/following-sibling::table//tr[td[a]]').map do |tr|
    tds = tr.css('td')
    who_to = tds[5].css('a[href*="/wiki/"]')
    data = { 
      name: who_to.text,
      wikiname: who_to.attr('title').text,
      area: tds[0].text,
      area_id: area_id(tds[0].text),
      start_date: date_from(tds[1].text),
      replaced: tds[3].text,
      term: 10,
      source: url,
    }
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
ScraperWiki.save_sqlite([:id], terms, 'terms')

changes = scrape_byelections('https://en.wikipedia.org/wiki/List_of_by-elections_in_Tuvalu')
terms.each { |t| scrape_term(t, changes) }

