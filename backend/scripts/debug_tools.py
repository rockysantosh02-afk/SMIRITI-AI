"""Command-line Firebase inspection and test-data helpers."""

import argparse
import json

from app.core.firebase_admin import get_firestore, verify_firebase_token


def view_collection(name: str, user_id: str | None = None) -> None:
    query = get_firestore().collection(name)
    if user_id:
        query = query.where("user_id", "==", user_id)
    print(json.dumps([{"id": item.id, **(item.to_dict() or {})} for item in query.stream()], default=str, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Smriti AI backend debug tools")
    subparsers = parser.add_subparsers(dest="command", required=True)
    viewer = subparsers.add_parser("view-data")
    viewer.add_argument("collection")
    viewer.add_argument("--user-id")
    args = parser.parse_args()
    if args.command == "view-data":
        view_collection(args.collection, args.user_id)


if __name__ == "__main__":
    main()
