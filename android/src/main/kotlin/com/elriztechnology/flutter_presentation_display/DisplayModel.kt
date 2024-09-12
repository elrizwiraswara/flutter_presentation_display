package com.elriztechnology.flutter_presentation_display

import androidx.annotation.Keep
import com.google.gson.annotations.SerializedName

@Keep
data class DisplayModel(
    @SerializedName("displayId")
    val displayId: Int,
    @SerializedName("flags")
    val flags: Int,
    @SerializedName("rotation")
    val rotation: Int,
    @SerializedName("name")
    val name: String
)