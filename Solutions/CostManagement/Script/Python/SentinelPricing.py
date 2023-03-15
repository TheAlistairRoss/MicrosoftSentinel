# SentinelPricing

from datetime import datetime
import SentinelPricingModule as SPM
import SentinelPricingConstants as SPC




def main():
    current_datetime = datetime.now().strftime('%Y/%m/%d %H:%M:%S')

    for service in services:
        for currencyCode in currencyCodes:
            
