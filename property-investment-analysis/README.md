# Property Investment Analysis

A command-line Python project for loading property records, calculating descriptive statistics, converting prices, normalising land size, visualising distributions and sales trends, and locating a target price.

## Features

- Load and validate property data from CSV.
- Convert AUD prices with a user-supplied exchange rate.
- Summarise bedrooms, bathrooms, and parking spaces by suburb.
- Convert supported land-size units to square metres and calculate averages.
- Save property-value histograms and yearly sales-trend charts locally.
- Sort prices in descending order with insertion sort and search with recursive binary search.
- Handle missing files, invalid arguments, missing columns, and empty results.

## Structure

```text
main.py                  Program entry point
investor.py              Command-line interaction
simple_data_analyser.py  Data loading, statistics, sorting, and search
data_visualiser.py       Matplotlib charts
```

## Requirements

- Python 3.10 or later
- pandas
- numpy
- matplotlib

Install dependencies:

```bash
python -m pip install -r requirements.txt
```

## Data

The original course dataset is not redistributed. Place a CSV file named `property_information.csv` in this directory, or enter another path when the program starts.

The implementation expects fields including `suburb`, `price`, `bedrooms`, `bathrooms`, `parking_spaces`, `land_size`, `land_size_unit`, and `sold_date`.

## Run

```bash
python main.py
```

Charts are written to the local `output/` directory.

