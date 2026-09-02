from debug_tools import view_collection
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("collection")
parser.add_argument("--patient-id")
args = parser.parse_args()
view_collection(args.collection, args.patient_id)
