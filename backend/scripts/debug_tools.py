"""Command-line Firebase inspection and test-data helpers."""

import argparse
import json

from app.core.firebase_admin import get_firestore, verify_firebase_token
from app.core.security import create_access_token, decode_access_token


def view_collection(name: str, patient_id: str | None = None) -> None:
    query = get_firestore().collection(name)
    if patient_id:
        query = query.where("patient_id", "==", patient_id)
    print(json.dumps([{"id": item.id, **(item.to_dict() or {})} for item in query.stream()], default=str, indent=2))


def main() -> None:
    parser = argparse.ArgumentParser(description="Smriti AI backend debug tools")
    subparsers = parser.add_subparsers(dest="command", required=True)
    viewer = subparsers.add_parser("view-data")
    viewer.add_argument("collection")
    viewer.add_argument("--patient-id")
    token = subparsers.add_parser("jwt")
    token.add_argument("uid")
    args = parser.parse_args()
    if args.command == "view-data":
        view_collection(args.collection, args.patient_id)
    else:
        print(create_access_token({"sub": args.uid}))


if __name__ == "__main__":
    main()
