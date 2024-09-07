import pandas as pd
import argparse


parser = argparse.ArgumentParser()
parser.add_argument("freqrnc", help="Path to freqrnc2011.csv")
parser.add_argument("output", help="Output")
args = parser.parse_args()

df = pd.read_csv(args.freqrnc, sep="\t")
df.loc[df["PoS"] == "s"]

new_df = pd.DataFrame(index=df[df["PoS"] == "s"]["Lemma"])
new_df.to_pickle(args.output)
