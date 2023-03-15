import os
from datetime import datetime
import requests

# Constants

services = ['Azure Monitor', 'Sentinel']
currencyCodes = ['USD', 'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'DKK', 'EUR', 'GBP', 'INR', 'JPY', 'KRW', 'NOK', 'NZD', 'RUB', 'SEK', 'TWD']
baseUrl = "https://prices.azure.com/api/retail/prices?api-version=2021-10-01-preview"

previousTier = {
    'Pay-as-you-go' : '',
    '100'  : 'Pay-as-you-go',
    '200'  : 100,
    '300'  : 200,
    '400'  : 300,
    '500'  : 400,
    '1000' : 500,
    '2000' : 1000,
    '5000' : 2000
}

filters = {
    'Azure Monitor' :"$filter=(serviceName eq 'Azure Monitor' or serviceName eq 'Log Analytics') and (meterName eq 'Pay-as-you-go Data Ingestion' or meterName eq '100 GB Commitment Tier Capacity Reservation' or meterName eq '200 GB Commitment Tier Capacity Reservation'  or meterName eq '300 GB Commitment Tier Capacity Reservation' or meterName eq '400 GB Commitment Tier Capacity Reservation' or meterName eq '500 GB Commitment Tier Capacity Reservation' or meterName eq '1000 GB Commitment Tier Capacity Reservation' or meterName eq '2000 GB Commitment Tier Capacity Reservation' or meterName eq '5000 GB Commitment Tier Capacity Reservation')",
    'Sentinel' : "$filter=(serviceName eq 'Sentinel') and (meterName eq 'Pay-as-you-go Analysis' or meterName eq '100 GB Commitment Tier Capacity Reservation' or meterName eq '200 GB Commitment Tier Capacity Reservation' or meterName eq '300 GB Commitment Tier Capacity Reservation' or meterName eq '400 GB Commitment Tier Capacity Reservation' or meterName eq '500 GB Commitment Tier Capacity Reservation' or meterName eq '1000 GB Commitment Tier Capacity Reservation' or meterName eq '2000 GB Commitment Tier Capacity Reservation' or meterName eq '5000 GB Commitment Tier Capacity Reservation')" 
}

class SentinelPricing:
    """This class represents the data from prices.azure.com for specific meters for Azure Monitor and Sentinel."""
    def __init__(self, time_generated, service_name: str, arm_region_name : str, currency_code : str, tier : str, unit_of_measure : str, retail_price : float, effective_start_date : str) -> None:
        self.time_generated = time_generated
        self.service_name = service_name
        self.arm_region_name = arm_region_name
        self.currency_code = currency_code
        self.tier = tier 
        self.unit_of_measure = unit_of_measure 
        self.retail_price = retail_price
        self.effective_start_date = effective_start_date

        if tier == "Pay-as-you-go":
            self.effective_price_per_gb = float(retail_price)
        else:
            self.effective_price_per_gb = float(int(tier) / retail_price)
    
    def add_effective_next_tier_gb(self, previous_tier_effective_price_per_gb):
        self.effective_next_tier_gb = self.retail_price / previous_tier_effective_price_per_gb


def get_sentinel_pricing (service=None, currency_code=None, time_generated=None):

    # Begin: Check Parameters
    if time_generated is None:
        time_generated = datetime.now().strftime('%Y/%m/%d %H:%M:%S')
        print(f'Parameters: service={service}, currencyCode={currency_code}, time_generated=(DefaultParam){time_generated}')
    else:
        print(f'Parameters: service={service}, currencyCode={currency_code}, time_generated={time_generated}')

    if service is None or currency_code is None:
        print(f'You must provide values to the "service" and "currency_code" parameters. Exiting')
        return

    startingUrl = f"{baseUrl}&currencyCode={currency_code}&{filters[service]}"
    print(f'\nInitial URL: {startingUrl}')

    itemsReturned = 0
    azPriceslist = []

    url = startingUrl
    while True:
        response = requests.get(url)
        if response.status_code != 200:
            print("Error: Unable to fetch data")
            break

        data = response.json()
        itemsReturned += data['Count']

        # Create new instance of the SentinelPricing class and add them to the output list
        for dataItem in data['Items']:
            # Filter out 0 retail prices as we aren't interested in free trials / tiers
            if dataItem['retailPrice'] != 0:
                SentinelPricingInstance = SentinelPricing(
                    time_generated = time_generated,
                    service_name = service,
                    arm_region_name = dataItem['armRegionName'],
                    currency_code = currency_code,
                    tier = dataItem['meterName'].split()[0],
                    unit_of_measure = dataItem['unitOfMeasure'],
                    retail_price = dataItem['retailPrice'],
                    effective_start_date = dataItem['effectiveStartDate']
                )

                azPriceslist.append(SentinelPricingInstance)

        # Determine if there is a next link, if not break the loop
        if data['NextPageLink']:
            url = data['NextPageLink']
        elif data['Count'] == 100:
            url = f'{startingUrl}&$skip={itemsReturned}'
        else:
            print(f'Total Items Returned: {itemsReturned}')
            break

    return azPriceslist
