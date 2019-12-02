if exists('*lg#set_stl')
    call lg#set_stl('%y%=%l ', '%y')
else
    setl stl=%y%=%l
endif

