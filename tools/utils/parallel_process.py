import asyncio
import traceback
from collections.abc import Awaitable, Callable, Sequence
from typing import Literal

from pydantic import BaseModel
from rich.console import Console
from tqdm.asyncio import tqdm


class ProcessingSuccess[Out](BaseModel):
    status: Literal["success"] = "success"
    value: Out


class ProcessingError(BaseModel):
    status: Literal["error"] = "error"
    error: str


class ProcessingCancelled(BaseModel):
    status: Literal["cancelled"] = "cancelled"


type ProcessingResult[Out] = (
    ProcessingSuccess[Out] | ProcessingError | ProcessingCancelled
)


async def parallel_process[In, Out](
    items: Sequence[In],
    process_item: Callable[[In], Awaitable[Out]],
    *,
    console: Console,
    progress_description: str = "Processing",
    max_parallel_requests: int = 16,
) -> list[ProcessingResult[Out]]:
    pbar = tqdm(total=len(items), desc=progress_description)
    semaphore = asyncio.Semaphore(max_parallel_requests)

    async def do_process_item(item: In) -> ProcessingResult[Out]:
        async with semaphore:
            try:
                return ProcessingSuccess[Out](value=await process_item(item))
            except Exception as e:
                pbar.write(f"Error processing '{item}':\n{traceback.format_exc()}")
                return ProcessingError(error=str(e))
            finally:
                pbar.update(1)

    tasks = [asyncio.create_task(do_process_item(item)) for item in items]

    try:
        await asyncio.gather(*tasks, return_exceptions=True)
        pbar.close()
    except (KeyboardInterrupt, asyncio.CancelledError):
        pbar.close()
        console.print("\nInterrupted. Aborting...")
        for task in tasks:
            if not task.done():
                task.cancel()

    results: list[ProcessingResult[Out]] = []
    for task in tasks:
        if task.cancelled():
            results.append(ProcessingCancelled())
        else:
            results.append(task.result())
    return results
