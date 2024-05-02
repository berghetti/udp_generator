import os
import glob
import polars as pl
from typing import List

# Define the base folder containing the rate folders
base_folder = '/proj/demeter-PG0/users/fabricio/afp_tests/tests/exponential/shorts-2us/afp-shorts-2us'

# Function to read the 'test' file in a given rate folder
def read_test_file(test_file: str) -> pl.DataFrame:
    df = pl.read_csv(test_file, separator='\t', has_header=False, new_columns=['type', 'latency'])
    return df

# Function to calculate tail statistics for a given DataFrame
def calculate_per_type_percentile(df: pl.DataFrame) -> pl.DataFrame:
    # Group by the first column and calculate statistics for the second column
    tail_value = df.group_by('type').agg(pl.col('latency').quantile(0.999))
    return tail_value

# Function to calculate the overall 99th percentile
def calculate_overall_percentile(df: pl.DataFrame) -> float:
    return df['latency'].quantile(0.999)

# Iterate over rate folders, read the test files, and calculate tail stats
results = []  # To store results from all folders

types = {1: 'shorts', 2: 'longs'}

def process_rates(rate_folders):
    for rate_folder in rate_folders:

        rate_folder_path = os.path.join(base_folder, rate_folder)
        tests = glob.glob(f'{rate_folder_path}/test[0-9]')
        #tests = [os.path.join(rate_folder_path, f) for f in os.listdir(rate_folder_path) if f.startswith("test")]

        for test in tests:
            r = glob.glob(f'{test}_*_result.csv')
            if len(r) > 0:
                print(f'{test} already processed... skiping...')
                #continue

            print(f'Processing {test}')

            # Read the data from the 'test' file
            df = read_test_file(test)

            # Calculate percentile
            per_type_percentile = calculate_per_type_percentile(df)
            overall_percentile = calculate_overall_percentile(df)

            for Type in per_type_percentile['type'].to_list():
                # Get the 99th percentile value for the current group
                group_df = per_type_percentile.filter(pl.col('type') == Type)

                # Create the file name for the output
                result_filename = f"{test}_{types[Type]}_99.9_result.csv"
                result_path = os.path.join(rate_folder_path, result_filename)

                # Save the group's 99th percentile data to CSV
                group_df.select('latency').write_csv(result_path, has_header=False)

             # Save the overall 99th percentile
            overall_result_filename = f"{test}_overall_99.9_result.csv"
            overall_result_path = os.path.join(rate_folder_path, overall_result_filename)

            overall_result_df = pl.DataFrame({'latency': [overall_percentile]})
            overall_result_df.select('latency').write_csv(overall_result_path, has_header=False)

# Get the list of rate folders
rate_folders = [f for f in os.listdir(base_folder) if os.path.isdir(os.path.join(base_folder, f))]
rate_folders = sorted(rate_folders, key=lambda x: int(x.split('_')[-1]))

process_rates(rate_folders)
