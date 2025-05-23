import pandas as pd
import numpy as np
import argparse
import matplotlib.pyplot as plt

# Define the hydro frequency
hydro_freq = 1420.40575177e6  # in Hz

def plot_metrics(metrics_df):

    # Plot stacked bar chart
    cmap = plt.get_cmap("tab20")  # Use a colormap with more distinct colors
    colors = [cmap(i) for i in range(len(metrics_df.columns))]
    metrics_df.plot(kind='bar', stacked=True, figsize=(10, 6), color=colors)

    # Add labels and title
    plt.xlabel("Configuraion Id")
    plt.ylabel("Time (s)")
    plt.title("Timing Breakdown by Experiment")

    # Rotate x-axis labels for better readability
    plt.xticks(rotation=45, ha='right')

    # Add legend
    plt.legend(title="Timing Components")

    # Show the plot
    plt.tight_layout()
    plt.savefig("profiles.png")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Process radio astronomy data.")
    parser.add_argument('-f', '--file', type=str, required=True, help='Metrics file to process')
    args = parser.parse_args()
    file_path = args.file

    # Example usage
    profile_df = pd.read_csv(file_path)
    # Check for unique numbers in the column 'config_id'
    if not profile_df['Config ID'].is_unique:
        raise ValueError("The 'config_id' column does not contain unique values.")
    profile_df.set_index('Config ID', inplace=True)
    # Proceed with the data
    timing_columns = [
                      'Time Hanning Generation',
                      'Time Hanning Window',
                      'Time Window Reduction',
                      'Time FFT',
                      'Time Magnitude',
                      'Time Normalization',
                      'Time Reordering FFT',
                      'Time Frequency Generation',
                      'Time Median Averaging',
                      'Time Peak Smoothing',
                      'Time Gauss Smoothing',
                      'Time Calibration',
                      'Time Peak Detection',
                      'Time Velocity',
                      ]
    profile_df = profile_df[timing_columns] / 1e9
    plot_metrics(profile_df)