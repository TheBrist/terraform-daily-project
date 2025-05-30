/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

output "certificate_ids" {
  description = "Certificate ids."
  value       = { for k, v in google_certificate_manager_certificate.certificates : k => v.id }
}

output "certificates" {
  description = "Certificates."
  value       = google_certificate_manager_certificate.certificates
}

output "dns_authorizations" {
  description = "DNS authorizations."
  value       = google_certificate_manager_dns_authorization.dns_authorizations
}

output "map" {
  description = "Map."
  value       = var.map == null ? null : google_certificate_manager_certificate_map.map[0]
}

output "map_id" {
  description = "Map id."
  value       = var.map == null ? null : google_certificate_manager_certificate_map.map[0].id
}
