
import json
from pathlib import Path

DATASET = Path(__file__).parent / "dataset" / "train.jsonl"

REQUIRED_OUTPUT = {
    "species", "breed", "affected_count",
    "death_count", "symptoms", "onset",
    "vaccination", "treatment", "summary"
}

def validate(record):
    assert set(record.keys()) == {"input", "context", "output"}

    inp = record["input"]
    ctx = record["context"]
    out = record["output"]

    assert set(inp.keys()) == {"report", "source"}
    assert isinstance(inp["report"], str) and inp["report"].strip()
    assert inp["source"] in {"text", "voice", "image", "document"}

    assert set(ctx.keys()) == {"location", "animal_id", "herd_id"}
    assert set(out.keys()) == REQUIRED_OUTPUT

    for field in ["species", "breed", "summary"]:
        assert out[field] is None or isinstance(out[field], str)

    for field in ["affected_count", "death_count"]:
        value = out[field]
        assert value is None or (
            type(value) is int and value >= 0
        )

    assert isinstance(out["symptoms"], list)
    assert all(isinstance(s, str) for s in out["symptoms"])

    onset = out["onset"]
    assert set(onset.keys()) == {"value", "unit"}
    assert onset["value"] is None or (
        type(onset["value"]) in (int, float)
        and onset["value"] >= 0
    )
    assert onset["unit"] is None or isinstance(onset["unit"], str)

    vaccination = out["vaccination"]
    assert set(vaccination.keys()) == {"status", "last_date"}

    treatment = out["treatment"]
    assert set(treatment.keys()) == {"given", "details"}
    assert treatment["given"] is None or type(treatment["given"]) is bool

def main():
    valid = 0
    errors = 0

    with DATASET.open(encoding="utf-8") as file:
        for line_number, line in enumerate(file, 1):
            if not line.strip():
                continue

            try:
                record = json.loads(line)
                validate(record)
                valid += 1
            except (ValueError, TypeError, AssertionError, KeyError) as e:
                errors += 1
                print(f"Line {line_number}: Invalid - {e}")

    print(f"Valid examples: {valid}")
    print(f"Invalid examples: {errors}")

if __name__ == "__main__":
    main()