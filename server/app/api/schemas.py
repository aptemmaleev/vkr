from pydantic import BaseModel
from typing import Union, List

class ReviewsIds(BaseModel):
    marketplace: str
    article: str
    ids: List[str]