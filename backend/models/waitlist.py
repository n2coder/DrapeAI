from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, field_validator
import re


class WaitlistRequest(BaseModel):
    email: EmailStr
    name: Optional[str] = None

    @field_validator("name")
    @classmethod
    def sanitize_name(cls, v):
        if v is None:
            return v
        # Strip HTML tags
        v = re.sub(r"<[^>]+>", "", v.strip())
        if len(v) > 80:
            raise ValueError("Name must not exceed 80 characters")
        return v or None


class WaitlistEntry(BaseModel):
    id: str
    email: str
    name: Optional[str]
    source: str
    created_at: datetime
