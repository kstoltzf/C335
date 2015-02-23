
	srinit
	srsns
	sjgti  Rb,$500,Rstop
	srspdi $1,$1

sloop:
	srsns
	sjgti Rb,$500,Rstop
	sjmp  sloop

Rstop:
	srspdi $0,$0

Pend:
	sjmp Pend