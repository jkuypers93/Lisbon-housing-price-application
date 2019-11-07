#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed Feb  6 17:07:21 2019

@author: jkuypers
"""

import scrapy
from scrapy import Request

from housingLisbon.items import HousinglisbonItem

class SapoSpider(scrapy.Spider):
    name = 'sapo'
    
    urls = [
                'https://casa.sapo.pt/en_GB/For-sale/Apartments/Lisboa/?sa=11'
                ]
    
    #for i in range(2, 20):
    #    urls.append('https://casa.sapo.pt/en_GB/For-sale/Apartments/Lisboa/?sa=11&pn='+str(i)+'')
        
    def start_requests(self):
        urls = [
                'https://casa.sapo.pt/en_GB/To-rent/Apartments/Lisboa/?sa=11'
                ]
        
        for i in range(2, 67):
            urls.append('https://casa.sapo.pt/en_GB/For-sale/Apartments/Lisboa/?sa=11&pn='+str(i)+'')
        
        for url in urls:
            yield scrapy.Request(url = url, callback = self.parse)
            
    def parse_pages(self, response):
        next_page_url = response.xpath("//div[@class='paginador']//a[text()='Next']/@href").extract.first()
        
        for href in response.css("div.propName a::attr(href)"):
            url = response.urljoin(href.extract())
            yield Request(url, callback=self.parse_details)
        yield Request(next_page_url, callback=self.parse)
            
    def parse(self, response):
        item = HousinglisbonItem()
        
        #for div in response.xpath("//div[contains(@class, 'searchResultProperty')]"):
            
        item = {
                'title' : response.xpath("//a/p[contains(@class, 'searchPropertyTitle')]/span/text()").extract(),
                'price' : response.xpath("//a/div[contains(@class, 'searchPropertyPrice')]/div/p/span/text()").extract(),
                'area' : response.xpath("//div[contains(@class, 'searchPropertyInfo')]/div/p/text()").extract(),
        }
        yield item
            

