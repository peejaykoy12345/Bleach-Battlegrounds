local ByteNetMax = require(script.ByteNetMax)

return {
    Character = ByteNetMax.defineNamespace("Character", function()
        return {
            packets = {
                OnMoveCooldown = ByteNetMax.definePacket({
                    value = ByteNetMax.struct({
                        MoveName = ByteNetMax.string,
                        CooldownTime = ByteNetMax.int16,
                    })
                })
            },
            queries = {},
        }
    end)
}