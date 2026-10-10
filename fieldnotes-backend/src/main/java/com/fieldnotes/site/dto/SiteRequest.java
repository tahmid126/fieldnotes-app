package com.fieldnotes.site.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SiteRequest {

    private UUID id; // Optional (offline sync)

    @NotBlank(message = "Site name is required")
    private String name;

    @NotBlank(message = "Site address is required")
    private String address;

    @NotNull(message = "Customer ID is required")
    private UUID customerId;
}
