from typing import Literal

from litellm import Choices, acompletion
from litellm.cost_calculator import completion_cost
from litellm.types.utils import ModelResponse
from pydantic import BaseModel
from tenacity import retry, stop_after_attempt, wait_exponential

ReasoningEffort = Literal["none", "minimal", "low", "medium", "high", "default"]


class SimpleLlmResponse(BaseModel):
    text: str
    cost_usd: float


async def simple_llm_request(
    *,
    model: str,
    reasoning_effort: ReasoningEffort | None = None,
    system_message: str,
    user_message: str,
):
    @retry(
        wait=wait_exponential(min=2, max=30),
        stop=stop_after_attempt(3),
    )
    async def do_gen():
        return await acompletion(
            model=model,
            reasoning_effort=reasoning_effort,
            messages=[
                {"role": "system", "content": system_message},
                {"role": "user", "content": user_message},
            ],
        )

    response = await do_gen()
    assert isinstance(response, ModelResponse)
    assert len(response.choices) == 1
    assert isinstance(response.choices[0], Choices)
    message = response.choices[0].message
    assert message.content is not None, response.model_dump_json(indent=2)
    cost = completion_cost(completion_response=response, model=model)
    return SimpleLlmResponse(
        text=message.content,
        cost_usd=cost,
    )
