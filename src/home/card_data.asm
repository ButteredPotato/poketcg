; load data of card with text id of name at de to wLoadedCard1
LoadCardDataToBuffer1_FromName::
	ld hl, CardPointers + 2 ; skip first NULL pointer
	ld a, BANK(CardPointers)
	call BankpushROM2
.find_card_loop
	ld a, [hli]
	or [hl]
	jr z, .done
	push hl
	ld a, [hld]
	ld l, [hl]
	ld h, a
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld bc, CARD_DATA_NAME
	add hl, bc
	ld a, [hli]
	cp e
	jr nz, .no_match
	ld a, [hl]
	cp d
.no_match
	pop hl
	pop hl
	inc hl
	jr nz, .find_card_loop
	dec hl
	ld a, [hld]
	ld l, [hl]
	ld h, a
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld de, wLoadedCard1
	ld b, PKMN_CARD_DATA_LENGTH
.copy_card_loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy_card_loop
	pop hl
.done
	call BankpopROM
	ret

; load data of card with id at e to wLoadedCard2
LoadCardDataToBuffer2_FromCardID::
	push hl
	ld hl, wLoadedCard2
	jr LoadCardDataToHL_FromCardID

; load data of card with id at e to wLoadedCard1
LoadCardDataToBuffer1_FromCardID::
	push hl
	ld hl, wLoadedCard1
;	fallthrough

LoadCardDataToHL_FromCardID::
	push de
	push bc
	push hl
	call GetCardPointer
	pop de
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld b, PKMN_CARD_DATA_LENGTH
.copy_card_data_loop
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy_card_data_loop
	call BankpopROM
	or a
.done
	pop bc
	pop de
	pop hl
	ret

; return in a the type (TYPE_* constant) of the card with id at e
GetCardType::
	push hl
	call GetCardPointer
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld l, [hl]
	call BankpopROM
	ld a, l
	or a
.done
	pop hl
	ret

; return in de the 2-byte text id of the name of the card with id at e
GetCardName::
	push hl
	call GetCardPointer
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld de, CARD_DATA_NAME
	add hl, de
	ld e, [hl]
	inc hl
	ld d, [hl]
	call BankpopROM
	or a
.done
	pop hl
	ret

; from the card id in a, returns type into a, rarity into b, and set into c
GetCardTypeRarityAndSet::
	push hl
	push de
	ld d, 0
	ld e, a
	call GetCardPointer
	jr c, .done
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld e, [hl] ; CARD_DATA_TYPE
	ld bc, CARD_DATA_RARITY
	add hl, bc
	ld b, [hl] ; CARD_DATA_RARITY
	inc hl
	ld c, [hl] ; CARD_DATA_SET
	call BankpopROM
	ld a, e
	or a
.done
	pop de
	pop hl
	ret

; return at hl the pointer to the data of the card with id at e
; return carry if e was out of bounds, so no pointer was returned
GetCardPointer::
	push de
	push bc
	; Load LSB from E into HL LSB(L)
	ld l, e
	; Load MSB from D into HL MSB(H)
	ld h, d
	; each card pointer is two bytes, so 2x the ID is the offset
	add hl, hl
	; Load a pointer to the start of the card table into bc
	ld bc, CardPointers
	; Add the start pointer to the offset
	add hl, bc
	ld a, h
	cp HIGH(CardPointers + 2 + (2 * NUM_CARDS))
	jr nz, .nz
	ld a, l
	cp LOW(CardPointers + 2 + (2 * NUM_CARDS))
.nz
	ccf  ; complement (C)arry flag, flip the value of the (C)arry flag. If this is set, one of the two previous comparisons(cp) resulted in a less than max, so we know its not out of bounds.
	jr c, .out_of_bounds ; If the (C)arry flag is set after the CCF, meaning our comparisons resulted in greater than, jump to out of bounds
	ld a, BANK(CardPointers)
	call BankpushROM2
	ld a, [hli]
	ld h, [hl]
	ld l, a
	call BankpopROM
	or a
.out_of_bounds
	pop bc
	pop de
	ret

; input:
; hl = card_gfx_index
; de = where to load the card gfx to
; bc are supposed to be $30 (number of tiles of a card gfx) and TILE_SIZE respectively
; card_gfx_index = (<Name>CardGfx - CardGraphics) / 8  (using absolute ROM addresses)
; also copies the card's palette to wCardPalette
LoadCardGfx::
	ldh a, [hBankROM]
	push af
	push hl
	; first, get the bank with the card gfx is at
	srl h
	srl h
	srl h
	ld a, BANK(CardGraphics)
	add h
	call BankswitchROM
	pop hl
	; once we have the bank, get the pointer: multiply by 8 and discard the bank offset
	add hl, hl
	add hl, hl
	add hl, hl
	res 7, h
	set 6, h ; $4000 ≤ hl ≤ $7fff
	call CopyGfxData
	ld b, CGB_PAL_SIZE
	ld de, wCardPalette
.copy_card_palette
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .copy_card_palette
	pop af
	call BankswitchROM
	ret

; identical to CopyFontsOrDuelGraphicsTiles
CopyFontsOrDuelGraphicsTiles2::
	ld a, BANK(Fonts) ; BANK(DuelGraphics)
	call BankpushROM
	ld c, TILE_SIZE
	call CopyGfxData
	call BankpopROM
	ret
