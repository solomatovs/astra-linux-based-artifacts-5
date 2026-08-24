---
license: apache-2.0
base_model: Qwen/Qwen3-1.7B
tags:
  - onnx
  - onnxruntime-genai
  - int4
  - ukrainian
language:
  - uk
  - en
pipeline_tag: text-generation
---

# Qwen3-1.7B — ONNX Runtime GenAI, INT4, CPU

Conversion of [Qwen/Qwen3-1.7B](https://huggingface.co/Qwen/Qwen3-1.7B) to the ONNX Runtime GenAI
format, quantised to INT4 for CPU execution. Built for the on-device assistant in
[Diarion](https://github.com/), an offline diary application; published because no INT4
ORT-GenAI build of this model existed.

Nothing about the model's weights or behaviour was changed beyond quantisation.

## Files

| File | Purpose |
|---|---|
| `genai_config.json` | Runtime configuration; the folder is loaded as a whole |
| `model.onnx` + `model.onnx.data` | Graph and weights, ~1.1 GB together |
| `tokenizer.json`, `tokenizer_config.json` | Tokeniser |
| `chat_template.jinja` | Chat template — **required**; without it the model continues the prompt instead of answering |

## How it was built

```bash
pip install onnxruntime-genai==0.15.1 onnx onnx_ir torch transformers
python -m onnxruntime_genai.models.builder \
  -i ./Qwen3-1.7B -o ./qwen3-1.7b-int4 -p int4 -e cpu
```

Builder **0.15.x is required**: 0.14.1 segfaults on this model immediately after loading weights.
The output loads and runs correctly under the 0.14.1 *runtime*, so an application may pin the older
runtime and still use this build.

## Notes from use

- **Apply the chat template.** Feeding the raw prompt makes an instruct model behave like a base
  completion model; the output looks like the model failing when the measurement is what failed.
- **Give a worked example.** On a Ukrainian retrieval-QA set this model scored 1/4 when instructed
  in words alone — it enumerated every passage instead of choosing one — and 4/4 when the prompt
  carried a single example of the intended answer shape.
- **Qwen3 is a hybrid reasoning model.** Append `/no_think` to suppress `<think>` blocks.
- Roughly 18–23 tokens/s on a desktop CPU with `repetition_penalty=1.1` and greedy decoding.

## Licence

Apache-2.0, inherited from the base model.
