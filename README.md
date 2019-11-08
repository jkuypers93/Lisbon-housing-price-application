# Lisbon Housing Price Analysis Application
An R Shiny App presenting housing price data from Lisbon scraped from Casa Sapo (Portuguese real estate website - https://casa.sapo.pt/).

Link to the app: https://tinyurl.com/yyeek75o

Files:

-HousingLisbonScraper: ScraPy program, holds the scraper & the scraped files in csv format

-HousingLisbonShiny.R: R script for the Shiny App

-HousingLisbon_Project_SapoData.ipynb: Data preprocessing file


To run Scraper: Open a terminal/command at the location of the scraper 'housingLisbon' in your terminal run the following script 'scrapy crawl sapo -o sasa_sapo_550pages.csv -t csv' - this will save a csv in your file directory syntax: scrapy crawl SCRAPER_NAME -output FILENAME.csv -t csv
