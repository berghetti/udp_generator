#!/usr/bin/python3

import argparse
import json5 as json

def load_data(file):
    try:
      f = open(file, 'r')
    except:
        print('File not found')
        exit(1)
    else:
      with f:
        data = json.load(f)

    return data

def save_data(file, data):
    with open(file, 'w') as f:
        json.dump(data, f)

# Return dict with represent the policy
# data: dict[list]
# policy: str
# return: dict
def get_policy(data, policy):
    for i, d in enumerate(data):
        if policy in d:
            return i, d
    print('Policy not found')
    exit(1)

def rename_policy(file, current, new):
    data = load_data(file)
    _, pol = get_policy(data, current)
    pol[new] = pol.pop(current)
    save_data(file, data)

def remove_policy(file, policy):
    data = load_data(file)
    i, _ = get_policy(data, policy)
    del data[i]
    save_data(file, data)

if __name__ == "__main__":
    # Argument parser setup
    parser = argparse.ArgumentParser(description="Manage group policys in a JSON file.")
    subparsers = parser.add_subparsers(dest="action", required=True, help="Action to perform.")

    # Remove action
    remove_parser = subparsers.add_parser("remove", help="Remove a group policy.")
    remove_parser.add_argument("file", help="Path to the meta file.")
    remove_parser.add_argument("policy", help="The policy to remove.")

    # Rename action
    rename_parser = subparsers.add_parser("rename", help="Rename a group policy.")
    rename_parser.add_argument("file", help="Path to the meta file.")
    rename_parser.add_argument("old_policy", help="The policy to rename.")
    rename_parser.add_argument("new_policy", help="The new policy name.")

    args = parser.parse_args()

    if args.action == "remove":
        remove_policy(args.file, args.policy)
    elif args.action == "rename":
        rename_policy(args.file, args.old_policy, args.new_policy)
