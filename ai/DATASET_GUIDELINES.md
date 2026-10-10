
# JeevSwasth Dataset Annotation Guidelines

## Purpose

The dataset trains JeevSwasth AI to convert unstructured
livestock-health reports into structured health information.

## General Rules

1. Extract only information explicitly present in the input.
2. Never invent missing information.
3. Use null when information is unavailable.
4. Do not infer diseases from symptoms.
5. Do not generate risk scores.
6. Do not declare an outbreak.
7. Preserve the meaning of the original report.
8. The summary must contain only information supported by the report.

## Field Rules

### species

Use the animal species explicitly mentioned.

Examples:

- cow → cattle
- buffalo → buffalo
- goat → goat
- sheep → sheep

If unknown:
null

### breed

Extract the breed only when explicitly mentioned.

Unknown:
null

### affected_count

Extract the number of affected animals when explicitly stated.

Unknown:
null

### death_count

Only use 0 when the report explicitly states that there were no deaths.

Otherwise:
null

### symptoms

Store all explicitly reported symptoms as an array.

Example:
["fever", "loss of appetite", "weakness"]

### onset

Store the reported onset information.

Unknown:
{
  "value": null,
  "unit": null
}

### vaccination

Extract vaccination information only when explicitly provided.

### treatment

Extract treatment information only when explicitly provided.

### summary

Create a concise summary using only information present in the report.
