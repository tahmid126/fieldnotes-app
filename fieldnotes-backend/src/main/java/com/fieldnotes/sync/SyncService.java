package com.fieldnotes.sync;

import com.fieldnotes.customer.Customer;
import com.fieldnotes.customer.CustomerRepository;
import com.fieldnotes.customer.dto.CustomerResponse;
import com.fieldnotes.note.FieldNote;
import com.fieldnotes.note.FieldNoteRepository;
import com.fieldnotes.note.dto.FieldNoteResponse;
import com.fieldnotes.site.Site;
import com.fieldnotes.site.SiteRepository;
import com.fieldnotes.site.dto.SiteResponse;
import com.fieldnotes.sync.dto.SyncRequest;
import com.fieldnotes.sync.dto.SyncResponse;
import com.fieldnotes.user.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class SyncService {

    private final CustomerRepository customerRepository;
    private final SiteRepository siteRepository;
    private final FieldNoteRepository fieldNoteRepository;

    @Transactional
    public SyncResponse syncData(SyncRequest request, User user) {
        LocalDateTime syncStartTime = LocalDateTime.now();

        // 1. Process incoming customers from client
        if (request.getCustomers() != null) {
            for (SyncRequest.SyncCustomerItem item : request.getCustomers()) {
                if (item.getId() == null) continue;

                Optional<Customer> existingOpt = customerRepository.findByIdAndUserId(item.getId(), user.getId());
                if (existingOpt.isPresent()) {
                    Customer existing = existingOpt.get();
                    existing.setName(item.getName());
                    existing.setContactInformation(item.getContactInformation());
                    existing.setDeleted(item.isDeleted());
                    existing.setUpdatedAt(syncStartTime);
                    customerRepository.save(existing);
                } else if (!item.isDeleted()) {
                    Customer newCustomer = Customer.builder()
                            .id(item.getId())
                            .name(item.getName())
                            .contactInformation(item.getContactInformation())
                            .user(user)
                            .deleted(false)
                            .createdAt(syncStartTime)
                            .updatedAt(syncStartTime)
                            .build();
                    customerRepository.save(newCustomer);
                }
            }
        }

        // 2. Process incoming sites from client
        if (request.getSites() != null) {
            for (SyncRequest.SyncSiteItem item : request.getSites()) {
                if (item.getId() == null || item.getCustomerId() == null) continue;

                Optional<Customer> customerOpt = customerRepository.findByIdAndUserId(item.getCustomerId(), user.getId());
                if (customerOpt.isEmpty()) continue;

                Customer customer = customerOpt.get();
                Optional<Site> existingOpt = siteRepository.findByIdAndUserId(item.getId(), user.getId());

                if (existingOpt.isPresent()) {
                    Site existing = existingOpt.get();
                    existing.setName(item.getName());
                    existing.setAddress(item.getAddress());
                    existing.setCustomer(customer);
                    existing.setDeleted(item.isDeleted());
                    existing.setUpdatedAt(syncStartTime);
                    siteRepository.save(existing);
                } else if (!item.isDeleted()) {
                    Site newSite = Site.builder()
                            .id(item.getId())
                            .name(item.getName())
                            .address(item.getAddress())
                            .customer(customer)
                            .user(user)
                            .deleted(false)
                            .createdAt(syncStartTime)
                            .updatedAt(syncStartTime)
                            .build();
                    siteRepository.save(newSite);
                }
            }
        }

        // 3. Process incoming notes from client
        if (request.getNotes() != null) {
            for (SyncRequest.SyncNoteItem item : request.getNotes()) {
                if (item.getId() == null || item.getSiteId() == null) continue;

                Optional<Site> siteOpt = siteRepository.findByIdAndUserId(item.getSiteId(), user.getId());
                if (siteOpt.isEmpty()) continue;

                Site site = siteOpt.get();
                Optional<FieldNote> existingOpt = fieldNoteRepository.findByIdAndUserIdAndDeletedFalse(item.getId(), user.getId());
                if (existingOpt.isEmpty()) {
                    // Try finding even if marked deleted
                    existingOpt = fieldNoteRepository.findAllByUserId(user.getId()).stream()
                            .filter(n -> n.getId().equals(item.getId()))
                            .findFirst();
                }

                if (existingOpt.isPresent()) {
                    FieldNote existing = existingOpt.get();
                    existing.setTitle(item.getTitle());
                    existing.setDescription(item.getDescription());
                    existing.setLocation(item.getLocation());
                    existing.setLatitude(item.getLatitude());
                    existing.setLongitude(item.getLongitude());
                    if (item.getNoteDateTime() != null) {
                        existing.setNoteDateTime(item.getNoteDateTime());
                    }
                    if (item.getStatus() != null) {
                        existing.setStatus(item.getStatus().toUpperCase());
                    }
                    existing.setPhotoUrl(item.getPhotoUrl());
                    existing.setSite(site);
                    existing.setDeleted(item.isDeleted());
                    existing.setUpdatedAt(syncStartTime);
                    fieldNoteRepository.save(existing);
                } else if (!item.isDeleted()) {
                    FieldNote newNote = FieldNote.builder()
                            .id(item.getId())
                            .title(item.getTitle())
                            .description(item.getDescription())
                            .location(item.getLocation())
                            .latitude(item.getLatitude())
                            .longitude(item.getLongitude())
                            .noteDateTime(item.getNoteDateTime() != null ? item.getNoteDateTime() : syncStartTime)
                            .status(item.getStatus() != null ? item.getStatus().toUpperCase() : "DRAFT")
                            .photoUrl(item.getPhotoUrl())
                            .site(site)
                            .user(user)
                            .deleted(false)
                            .createdAt(syncStartTime)
                            .updatedAt(syncStartTime)
                            .build();
                    fieldNoteRepository.save(newNote);
                }
            }
        }

        // 4. Gather server changes since lastSyncTimestamp
        List<CustomerResponse> updatedCustomers;
        List<SiteResponse> updatedSites;
        List<FieldNoteResponse> updatedNotes;

        if (request.getLastSyncTimestamp() != null) {
            updatedCustomers = customerRepository.findByUserIdAndUpdatedAtAfter(user.getId(), request.getLastSyncTimestamp())
                    .stream().map(CustomerResponse::fromEntity).collect(Collectors.toList());

            updatedSites = siteRepository.findByUserIdAndUpdatedAtAfter(user.getId(), request.getLastSyncTimestamp())
                    .stream().map(SiteResponse::fromEntity).collect(Collectors.toList());

            updatedNotes = fieldNoteRepository.findByUserIdAndUpdatedAtAfter(user.getId(), request.getLastSyncTimestamp())
                    .stream().map(FieldNoteResponse::fromEntity).collect(Collectors.toList());
        } else {
            updatedCustomers = customerRepository.findAllByUserId(user.getId())
                    .stream().map(CustomerResponse::fromEntity).collect(Collectors.toList());

            updatedSites = siteRepository.findAllByUserId(user.getId())
                    .stream().map(SiteResponse::fromEntity).collect(Collectors.toList());

            updatedNotes = fieldNoteRepository.findAllByUserId(user.getId())
                    .stream().map(FieldNoteResponse::fromEntity).collect(Collectors.toList());
        }

        return SyncResponse.builder()
                .serverTimestamp(syncStartTime)
                .customers(updatedCustomers)
                .sites(updatedSites)
                .notes(updatedNotes)
                .build();
    }

    @Transactional(readOnly = true)
    public SyncResponse getAllDataForRestore(User user) {
        List<CustomerResponse> customers = customerRepository.findAllByUserIdAndDeletedFalseOrderByNameAsc(user.getId())
                .stream().map(CustomerResponse::fromEntity).collect(Collectors.toList());

        List<SiteResponse> sites = siteRepository.findAllByUserIdAndDeletedFalseOrderByNameAsc(user.getId())
                .stream().map(SiteResponse::fromEntity).collect(Collectors.toList());

        List<FieldNoteResponse> notes = fieldNoteRepository.findAllByUserIdAndDeletedFalseOrderByNoteDateTimeDesc(user.getId())
                .stream().map(FieldNoteResponse::fromEntity).collect(Collectors.toList());

        return SyncResponse.builder()
                .serverTimestamp(LocalDateTime.now())
                .customers(customers)
                .sites(sites)
                .notes(notes)
                .build();
    }
}
