# ------------------------------------------------------------
# Property Investment Management System
# Author: xKevinx66
# ------------------------------------------------------------
"""
main.py

Program entry point for the Property Investment Management System.
Runs a text-based interface (menu) and includes commented test code as required.
"""

from investor import Investor


def main() -> None:
    app = Investor()
    app.run()


if __name__ == "__main__":
    main()

# ---------------------------------------------------------------------------
# Test code (REQUIRED): place test snippets for each functionality in comments
# ---------------------------------------------------------------------------
# 3.2 extract_property_info(file_path) -> DataFrame
# from simple_data_analyser import SimpleDataAnalyser
# de = SimpleDataAnalyser()
# df = de.extract_property_info("property_information.csv")
# len(df)
# # Expected (given provided CSV): 118771
#
# 3.3 currency_exchange(dataframe, exchange_rate) -> numpy array
# arr = de.currency_exchange(df, 0.66)  # AUD -> USD
# arr[:5]
# # Expected: a numpy array; first values should be price*0.66 (may include NaN)
#
# 3.4 suburb_summary(dataframe, suburb) -> None
# de.suburb_summary(df, "Point Cook")
# # Expected: prints mean/std/median/min/max for bedrooms, bathrooms, parking_spaces
# de.suburb_summary(df, "all")
#
# 3.5 avg_land_size(dataframe, suburb) -> float/None
# avg_pc = de.avg_land_size(df, "Point Cook")
# print(avg_pc)
# # Expected: float (m^2) or None if no valid land size values
#
# 3.6 prop_val_distribution(dataframe, suburb, target_currency="AUD") -> None
# from data_visualiser import DataVisualiser
# dv = DataVisualiser()
# dv.prop_val_distribution(df, "Point Cook", "USD")
# # Expected: saves histogram file to ./output/
#
# 3.7 sales_trend(dataframe) -> None
# dv.sales_trend(df)
# # Expected: saves ./output/sales_trend.png
#
# 3.8 locate_price(target_price, data, target_suburb) -> bool
# # Pick an existing price in the suburb for a True case:
# pc_prices = df[df["suburb"] == "Point Cook"]["price"].dropna()
# target = float(pc_prices.iloc[0])
# found_true = de.locate_price(target, df, "Point Cook")
# found_false = de.locate_price(123456789.0, df, "Point Cook")
# print(found_true, found_false)
# # Expected: True False

