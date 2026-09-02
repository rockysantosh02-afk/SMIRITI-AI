import argparse
from app.core.security import create_access_token

parser = argparse.ArgumentParser()
parser.add_argument("uid", nargs="?", default="test-user")
print(create_access_token({"sub": parser.parse_args().uid, "role": "patient"}))
