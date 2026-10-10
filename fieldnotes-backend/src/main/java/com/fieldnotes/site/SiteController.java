package com.fieldnotes.site;

import com.fieldnotes.common.dto.ApiResponse;
import com.fieldnotes.security.SecurityUtils;
import com.fieldnotes.site.dto.SiteRequest;
import com.fieldnotes.site.dto.SiteResponse;
import com.fieldnotes.user.User;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/sites")
@RequiredArgsConstructor
public class SiteController {

    private final SiteService siteService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<SiteResponse>>> getAllSites(
            @RequestParam(required = false) UUID customerId) {
        User user = SecurityUtils.getCurrentUser();
        List<SiteResponse> sites;
        if (customerId != null) {
            sites = siteService.getSitesByCustomerId(customerId, user);
        } else {
            sites = siteService.getAllSites(user);
        }
        return ResponseEntity.ok(ApiResponse.success(sites));
    }

    @GetMapping("/customer/{customerId}")
    public ResponseEntity<ApiResponse<List<SiteResponse>>> getSitesByCustomer(@PathVariable UUID customerId) {
        User user = SecurityUtils.getCurrentUser();
        List<SiteResponse> sites = siteService.getSitesByCustomerId(customerId, user);
        return ResponseEntity.ok(ApiResponse.success(sites));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SiteResponse>> getSiteById(@PathVariable UUID id) {
        User user = SecurityUtils.getCurrentUser();
        SiteResponse site = siteService.getSiteById(id, user);
        return ResponseEntity.ok(ApiResponse.success(site));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<SiteResponse>> createSite(@Valid @RequestBody SiteRequest request) {
        User user = SecurityUtils.getCurrentUser();
        SiteResponse created = siteService.createSite(request, user);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Site created successfully", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<SiteResponse>> updateSite(
            @PathVariable UUID id,
            @Valid @RequestBody SiteRequest request) {
        User user = SecurityUtils.getCurrentUser();
        SiteResponse updated = siteService.updateSite(id, request, user);
        return ResponseEntity.ok(ApiResponse.success("Site updated successfully", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteSite(@PathVariable UUID id) {
        User user = SecurityUtils.getCurrentUser();
        siteService.deleteSite(id, user);
        return ResponseEntity.ok(ApiResponse.success("Site deleted successfully", null));
    }
}
