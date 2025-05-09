Base.hash(x::ComponentArray, h::UInt) = hash(keys(x), hash(getdata(x), h))

Base.:(==)(x::ComponentArray, y::ComponentArray) = getdata(x)==getdata(y) && getaxes(x)==getaxes(y)
Base.:(==)(x::ComponentArray, y::AbstractArray) = getdata(x)==y && keys(x)==keys(y) # For equality with LabelledArrays
Base.:(==)(x::AbstractArray, y::ComponentArray) = y==x

Base.keys(x::ComponentVector) = keys(indexmap(getaxes(x)[1]))

Base.haskey(x::ComponentVector, s::Symbol) = haskey(indexmap(getaxes(x)[1]), s)

Base.propertynames(x::ComponentVector) = propertynames(indexmap(getaxes(x)[1]))

# Property access for ComponentVectors goes through _get/_setindex
@inline Base.getproperty(x::ComponentVector, s::Symbol) = _getindex(Base.maybeview, x, Val(s))
@inline Base.getproperty(x::ComponentVector, s::Val) = _getindex(Base.maybeview, x, s)

@inline Base.setproperty!(x::ComponentVector, s::Symbol, v) = _setindex!(x, v, Val(s))
@inline Base.setproperty!(x::ComponentVector, s::Val, v) = _setindex!(x, v, s)

Base.merge(a::NamedTuple, b::ComponentArray) = merge(a, NamedTuple(b))


@inline Base.getproperty(x::ComponentArray{T,N}, s::Symbol) where {T, N} = getproperty(x, Val(s))
@inline function Base.getproperty(x::ComponentArray{T,N}, s::Val) where {T, N}
    _getindex(Base.maybeview, x, s, ntuple((_)->Val(:), N-1)...)
end

@inline Base.setproperty!(x::ComponentArray{T,N}, s::Symbol, v) where {T, N} = setproperty!(x, Val(s), v)
@inline function Base.setproperty!(x::ComponentArray{T,N}, s::Val, v) where {T, N}
    setindex!(getproperty(x, s), v, ntuple((_)->:, N-1)...)
end
@inline function Base.setproperty!(x::ComponentArray{T,N}, s::Val, v::NamedTuple) where {T, N}
    setindex!(getproperty(x, s), v, ntuple((_)->:, N-1)...)
end
@inline Base.setproperty!(x::ComponentVector, s::Symbol, v::NamedTuple) = setproperty!(x, Val(s), v)
@inline Base.setproperty!(x::ComponentVector, s::Val, v::NamedTuple) = setindex!(getproperty(x, s), v, :)

@generated function Base.setindex!(x::ComponentArray, v::NamedTuple, ::Colon, trailing_idx::FlatOrColonIdx...)
    first_ax = first(getaxes(x))
    if keys(first_ax) != first(v.parameters)
        return :(error("Keys of ComponentArray does not match keys of assigned value"))
    end
    lines = Expr[:(sub = view(x, :, trailing_idx...))]
    for k in keys(first_ax)
        push!(lines, :(setproperty!(sub, $(QuoteNode(k)), getproperty(v, $(QuoteNode(k))))))
    end
    push!(lines, :(return v))
    return Expr(:block, lines...)
end
