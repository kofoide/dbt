select *
from {{ source('dvdrental', 'actor') }}
